---
title: Strings são estranhas
author: Gabriel Dertoni
date: May 26, 2021
lang: pt-br
lang-pt: true
keywords:
- C
- string
description: Como strings funcionam em C.
---

## Introdução

Quando estamos começando a programar, frequentemente encontramos as famosas
"strings". Elas são conjuntos de caracteres, palavras, frases, qualquer coisa
que se possa pensar como texto. Parece simples certo? Bem sim, o conceito em si
é simples, entretanto existem alguns detalhes na hora de usar elas em programa
que podem não ser imediatamente óbvios.

## Strings em C

Na linguagem C especialmente, todas as strings são terminadas por um caractere
`'\0'`. Esse delimitador serve para justamente indicar o fim de uma sequência de
caracteres. É uma forma de dizer "se você ler daqui pra frente, é possível que
dê merda". Esse valor especial, o `'\0'` é simplesmente o byte de valor 0. De
maneira geral há a vantagem de que podemos passar strings pra cá e pra lá apenas
como ponteiros para o primeiro caractere da cadeia, já que sabemos que podemos
ler a vontade até o `'\0'`. Na prática, isso facilita, já que não precisamos o
tempo todo dizer explicitamente quantos caracteres a string têm.

Ou seja, sempre que queremos representar uma string em C, pegamos o endereço ao
primeiro caractere da sequência e isso basta, a partir dele sabemos pegar o
próximo e o seguinte e assim por diante até o `'\0'`.

Então, de maneira mais específica, `char *` representa um ponteiro (variável que
armazena endereço de memória) que aponta para algum lugar qualquer da memória.
Esse lugar pode ser heap, stack ou para qualquer outra região da memória. O
valor no endereço de memória apontado pelo `char *` será algum caractere ou um
`'\0'`. Se for um caractere normal, sabemos que o endereço de memória seguinte,
também é parte da string. No endereço seguinte podemos verificar novamente se é
`'\0'` e se for, sabemos ter encontrado o endereço do fim da string.

## Strings estáticas

Nem todas as strings nascem iguais, algumas são fornecidas pelo usuário, algumas
lida de arquivos e algumas são forjadas dentro do binário do programa. Essas
últimas são as strings estáticas. Na hora de executar seu código, lá estão elas,
dentro do binário em si. É possível vê-las ao tentar abrir o binário do seu
programa num editor de texto qualquer. A maior parte será um monte de lixo, mas
ao procurar bem, lá estarão elas. Alternativamente o utilitário do Linux
`strings` imprime todos os caracteres imprimíveis na tela contidos em qualquer
binário.

Então, como criamos elas? Bem, você provavelmente já as viu ou usou! Elas são
criadas toda vez que escrevemos algo entre aspas duplas. Ou seja, quando seu
programa faz `printf("Hello, world!")`, esse `Hello, world!` estará forjado nas
entranhas binárias do seu executável!

Toda vez que você roda seu programa, o sistema operacional joga todo o binário
do programa para a memória RAM. Junto com as instruções em linguagem de máquina,
se encontra seu `Hello, world!`. A variável que você usa em C, na verdade é
apenas um ponteiro que aponta para o local na memória onde a sua string foi
posta. Um `char *` define uma variável que armazena um número. Esse número
representa um endereço na memória. Nesse endereço se encontra o primeiro
caractere da sua string.


Isso é muito importante! Strings estáticas estão efetivamente junto com o resto
do seu executável, elas não se encontram na stack ou muito menos heap.
Entretanto, essa região de memória onde o código fica não têm permissão de
escrita, ou seja, strings estáticas **não podem ser modificadas** e por isso
ganham esse nome. Ao tentar modificar uma string estática, seremos recebidos
pelo infame `Segfault`.

```c
int main() {
    // Será armazenada no binário do programa.
    char *minha_string_estatica = "Hello, world!";
    printf("%s", minha_string_estatica);
    //     ^^^^ olha outra string estática aqui!

    minha_srting_estatica[1] = 'h'; // Segfault!
    return 0;
}
```

Apesar de C ser uma linguagem que tende a te dar total liberdade, nesse caso, se
quisermos que o compilador verifique para nós que não estamos sem querer
tentando modificar uma string estática, podemos usar a palavra `const` ao
declarar uma variável. Ao fazermos isso, o compilador nos avisará toda vez que
tentarmos modificar essa variável e não teremos o terrível `Segfault`.

```c
const char *minha_string_estatica = "Hello, world!";
minha_srting_estatica[1] = 'h'; // Erro de compilação.
```

Além disso algumas funções podem receber um argumento `const char *` o que
significa que a função promete não tentar alterar o conteúdo naquela localização
de memória. Repare que o primeiro argumento do `printf` é `const`, ou seja, tudo
bem utilizarmos strings estáticas como primeiro argumento para essa função.

Por conta disso, quando estiver trabalhando com strings estáticas, **sempre use
`const`**.

## Strings alocadas na stack

Assim como qualquer variável na stack, strings na stack também não podem crescer
de tamanho e **possuem seu tamanho determinado em tempo de compilação**. Nesse
aspecto, a linguagem C dá uma mãozinha com sintaxe como veremos.

Para criar uma string na stack, usamos a mesma notação de *array*, afinal
strings são apenas *arrays* de caracteres.

```c
char nome[20] = "josimar";
printf("nome: %s\n", nome);
```

Olha só, ainda usamos as mesmas aspas da string estática e de fato, o lado
direito do `=` é realmente uma string estática! Mas algo mudou, ao fazermos

```c
char nome[20] = "josimar";
nome[0] = 'J';
printf("nome: %s\n", nome);
```

Não ocorre qualquer problema! Bem isso é porque o compilador está escondendo
alguns detalhes. Na realidade, ele cria a string estática `"josimar"` e separa
20 bytes para a variável `nome` na stack. Depois disso, ele coloca uma instrução
que copia a string estática para dentro da variável na stack. Na realidade, esse
código poderia ser reescrito da seguinte maneira

```c
char nome[20];
strcpy(nome, "josimar");
```

Aqui fica mais claro o que está realmente acontecendo. A operação `strcpy` só
acontece em tempo de execução, quando a stack já existe, e ela só copia os
conteúdos da string estática. Assim, podemos modificar livremente a variável
`nome`.

Entretanto, ainda temos que dizer explicitamente que essa string pode ter **no
máximo** 20 caracteres. Mas e se quisermos mudar o código? Teremos que ficar
contando os caracteres? E tem que lembrar do espaço pro `'\0'` no final! Bem,
existe uma saída. O compilador sabe contar o tamanho de strings estáticas, então
podemos só escrever

```c
char nome[] = "josimar";
```

E tudo se dá por resolvido.

Além disso, repare que podemos usar `char nome[]` no lugar de qualquer ponteiro
`char *`. Isso porque, na realidade, `char nome[]` é um ponteiro também, ele só
está escondido com uma cara diferente. Essa diferença só existe em tempo de
compilação.

Além disso, quando estamos usando strings na stack através de arrays de
caracteres, podemos tratar elas como tratamos qualquer vetor! Ou seja, se
quisermos calcular o tamanho da string, podemos fazer isso em tempo de
compilação utilizando o `sizeof`. Considerando o exemplo anterior com a variável
`nome`, podemos fazer

```c
// Aqui precisamos do -1 no final se não quisermos contar o '\0'.
int tamanho_nome = sizeof(nome) - 1;

```

Essa operação é inteiramente calculada em tempo de compilação, então nenhum
precioso ciclo de clock será gasto iterando na string até encontrar o `'\0'`!

## Strings na heap

Por fim, chegamos na heap, o lugar mais flexível de todos. Aqui as strings não
só podem ser alteradas como também podem crescer e diminuir de tamanho. A parte
chata é que temos que sempre trabalhar com um par de funções em especial:
`malloc` e `free`.

Além disso, o compilador não tem tantas boas surpresas como tinha no caso da
stack. Temos que manualmente usar `strcpy` ou ler de algum lugar.

```c
const char *nome = "Josh";
const char *sobrenome = "Johnson";
// Aloca espaço na heap para a string. Não esqueça do +1 para o '\0'.
char *heap_str = (char *)malloc((strlen(nome) + 1) * sizeof(char));

strcpy(heap_str, nome);
printf("nome: %s\n", heap_str);
// +1 para um espaço entre nome e sobrenome.
int novo_tamanho = strlen(nome) + strlen(sobrenome) + 1;
// Aumenta o tamanho alocado. +1 para o '\0'.
heap_str = (char *)realloc(heap_str, (novo_tamanho + 1) * sizeof(char));
// Adiciona um espaço depois do nome.
heap_str[strlen(nome)] = ' ';
// Copia o sobrenome para depois do nome e espaço.
strcpy(heap_str + strlen(nome) + 1, sobrenome);
printf("nome completo: %s\n", heap_str);
// Libera o espaço alocado na heap.
free(heap_str);
```

## Unicode e ASCII

Por padrão, o tipo `char`, da linguagem C possui apenas 1 byte em tamanho. Isso
significa que apenas caracteres ASCII podem caber em uma variável dessas. Ou
seja, letras com acento ou símbolos como `ç` não podem ser atribuídos a essas
variáveis.

Entretanto, existe um jeito. Na realidade, caracteres com acento ocupam 2 bytes
ou mais, mas é só isso que elas são. Isso significa que dentro de uma string
podemos sim usar acento, mas metade dos dados do caractere ficarão armazenados
em um endereço e a outra metade noutro. Isso dificulta alguns tipos de
processamento, por exemplo quando queremos comparar alfabeticamente duas
strings. Entretanto, sabendo disso, é sim possível utilizar acentos e caracteres
especiais (incluindo emojis) em strings de C. Quando a string for impressa no
terminal, os bytes que compõe o caractere especial serão só impressos em
sequência, e o terminal será capaz de detectar isso e interpretar como um lindo
emoji, ou qualquer coisa do gênero.

```c
const char *happy = "😊";
printf("%s\n", happy); // Funciona sem problemas.
```
