---
title: Como nunca sofrer de segfault e double free
author: Gabriel Dertoni
lang: pt-br
lang-pt: true
description: Uma técnica para evitar problemas com memória inspirado por Rust.
---

## Introdução

Nesse post, pretendo definir dois conceitos que podem ajudar na hora de usar
alocação dinâmica em linguagens sem gerenciamento de memória automático. O
primeiro conceito será mais simples, mas também limitado, já o segundo será um
pouco mais complexo, mas funciona de maneira mais genérica e pode ser aplicado a
uma variedade maior de casos.

## Quem aloca, libera

Muitas vezes ao escrever uma função ou um bloco de código, uma alocação dinâmica
é necessária, mas apenas localmente. Nesses casos, podemos os usar a ideia de
"quem aloca libera". Logo após escrever o código de alocação, adicionamos o
código de liberação logo em seguida, para garantir que não será esquecido.

```c
int minha_funcao() {
    int *ponteiro = (int *)malloc(10 * sizeof(int));
    free(ponteiro);
}
```

O resto do código pode ser inserido entre o `malloc`e o `free`. Nesse modelo,
não precisamos nos preocupar com nada além disso: escrever `malloc` seguido de
`free` e depois vem o resto. Além disso, devemos imaginar que a variável
`ponteiro` será a variável a ser liberada e por isso, não deve ser incrementada
ou coisas do gênero. Além disso, só iremos fornecer esse ponteiro a outras
funções se soubermos que essas outras funções **não liberarão a memória dele**,
apenas o `free` ao fim do bloco deve fazer isso.

## Donos da memória

Apesar da abordagem "quem aloca, libera" ter sua maior vantagem na simplicidade,
nem sempre ela é suficiente. Por exemplo, digamos que exista uma função
`readline` que lê uma linha da entrada padrão e retorna um ponteiro à string com
os caracteres dessa linha. Nesse caso, a função `readline` é quem aloca a
memória, mas ela precisa retornar essa memória ainda alocada e, por isso, não
pode a liberar (como [comentado num outro artigo](https://www.notion.so/Fun-es-puras-e-impuras-boas-pr-ticas-de-programa-o-5cc1e69008d3472c8badf9f291608458),
essas comportamentos devem ser documentadas).

Nesse texto, usarei posse e propriedade de forma intercambiável. Existe uma
diferença no sentido legal da palavra, mas para os propósitos desse texto, elas
se referirão ao mesmo conceito.

Para resolver esse problema, podemos usar o conceito de "dono ou proprietário da
memória". Um proprietário de memória é um ponteiro que aponta para um bloco
qualquer de memória armazenada na heap com a importante responsabilidade de ser
liberado. Esse ponteiro possui a posse de um bloco de memória e apenas ele deve
liberá-lo. Para evitar `double free` devemos garantir que exista apenas um
proprietário para cada alocação. No caso da função `readline`, diríamos que ela
retorna a posse de um ponteiro. A função que chamadora recebe essa posse numa
variável e então essa variável se torna a responsável por ser liberada. Por
exemplo

```c
// Retorna um ponteiro a uma alocação na heap que deve ser liberada através de `free`.
char *readline() { /* implementação */ }


void main() {
    // Input recebe a posse da memória alocada pela `readline`.
    char *input = readline();


    // Outro ponteiro ao bloco de memória, entretanto, não
    // consideramos ele como proprietário, apenas uma referência.
    char *ptr = &input[2];

    /* Resto do código */

    free(intput);
}
```

Pode parecer óbvio, mas para que isso realmente funcione, algumas regras devem ser seguidas.

1. A posse do ponteiro não pode ser multiplicada, deve haver a cada momento
   apenas **um** proprietário.
2. Quando um ponteiro proprietário chega ao final de seu uso, ele deve ceder a
   sua posse. A última instância disso é a função `free`, que toma como
   argumento a posse de um ponteiro e o libera, fazendo a posse "sumir".
3. Quando um ponteiro cede a posse de um bloco de memória, ele não pode mais ser
   liberado. Ele deixa de ser proprietário e se torna apenas uma referência ao
   bloco de memória. Entretanto, para manter as coisas mais seguras, podemos
   dizer que após ceder a posse, não devemos nunca mais usar esse ponteiro.

### Estruturas sempre alocadas na heap

Em alguns casos, é necessário escrever uma função de criação e liberação para
alguma estrutura de dados customizada. Quando esse é o caso, haverá alguma
função `liberar_estrutura()` que internamente libera todos os blocos
necessários. Nesse caso, podemos dizer que a função de liberação toma
propriedade do ponteiro. Por isso, após chamá-la, o ponteiro não pode mais ser
liberado, já que não é mais proprietário. Um exemplo

```c
// Um nó de uma lista encadeada.
struct No {
    int valor;
    struct No *prox;
};

// Função aloca um nó na heap e retorna um ponteiro a ele que deve ser liberado
// através da função `no_liberar`.
struct No *no_criar(int valor);

// Aponta o `prox` do primeiro nó para o segundo nó. Toma uma referência ao
// primeiro nó e a propriedade do segundo. Já que, ao ligar os dois nós e ao
// liberar o primeiro nó com `no_liberar`, liberaremos ambos.
void no_link(struct No *aponta, struct No *prox);

// Libera um nó e todos os nós encadeados a ele.

void no_liberar(struct No *no);

void main() {
    // Adquire propriedade do ponteiro.
    struct No *ponta = no_criar(2);

    // Podemos até criar um escopo (opcional) para delimitar onde podemos usar
    // a variável `proximo`, já que sabemos que ela irá ceder sua propriedade
    // e não deve mais ser usada depois. Isso faz o compilador trabalhar ao
    // nosso favor mas pode tornar o código excessivamente aninhado em alguns
    // cenários.
    {
        // Aqui `proximo` possui a propriedade de um bloco de memória.
        struct No *proximo = no_criar(10);

        // `proximo` perde a propriedade de seu bloco de memória, como descrito no
        // comentário da função.
        no_link(ponta, proximo);
    }


    /* resto do código */

    // cede a propriedade do ponteiro. Aqui liberaremos ambos os blocos alocados
    // na heap.
    no_liberar(ponta);

    // `ponta->valor` não pode mais ser acessado.
}
```

### Trabalhando com estruturas

Uma outra situação possível é quando criamos estruturas que em si são alocadas
na *stack*, mas contém ponteiros para dados na *heap*.

```c
struct Vec {
    int len;
    int cap;
    int *ptr;
};

// Cria um vetor que contém dados na heap e deve ser liberado através da
// função `vec_free`.
struct Vec vec_new();
void vec_push(struct Vec *v, int val);
void vec_len(const struct Vec *v);

void vec_free(Vec v);

void main() {
    // A variável `inteiros` tem a propriedade de um vetor.
    struct Vec inteiros = vec_new();

    // Cedemos referências a esse bloco de memória, elas não podem liberar
    // a memória na heap pela convenção.
    vec_push(&inteiros, 80);
    vec_push(&inteiros, 42);

    vec_free(inteiros);
    // Não podemos mais usar a variável `inteiros`.
}
```

Aqui podemos diferenciar o que é proprietário e do que é referência. Podemos
definir que, o variáveis do tipo `struct Vec` serão proprietárias, e `struct Vec
*` será uma referência. Assim fica fácil! A função `vec_new()` claramente
retorna `struct Vec` o que é uma propriedade. Além disso `vec_free` recebe uma
propriedade, ou seja, alguma variável precisa ceder sua propriedade para poder
chamar essa função.

Isso torna intuitivo o conceito de posse e referência, quando vemos um ponteiro
sabemos se tratar de uma referência que pode modificar a estrutura. Um ponteiro
`const` é uma referência imutável e um tipo que não é um ponteiro representa uma
posse.

### Comentários eficientes

Uma possibilidade de notação que desenvolvi é inspirado pela linguagem
[Rust](https://www.rust-lang.org/pt-BR). Ao comentar os argumentos que uma
função recebe, quando for um ponteiro, podemos denotar de uma forma dentre
algumas possibilidades:

- `[ref]` para referências que não modificam o conteúdo, um ponteiro constante.

- `[ref mut]` para referências que modificam o conteúdo.
- `[ownership]` para um parâmetro que transfere posse.

Com essa notação podemos reescrever os comentários de um dos exemplos anteriores

```c
// Um nó de uma lista encadeada.
struct No {
    int valor;

    struct No *prox;
};


/**

 * Cria um nó alocado na heap com o valor especificado.
 * Parâmetros:

 *   valor - o valor que o nó conterá.
 * retorna - um nó alocado na heap. [ownership]
 */
struct No *no_criar(int valor);

/**
 * Conecta dois nós fazendo com que o `prox` do primeiro aponte para o segundo.
 * Parâmetros:
 *   aponta - o nó que terá o `prox` alterado. [ref mut]
 *   prox - o nó para o qual `aponta->prox` apontará. [ownership]
 */
void no_link(struct No *aponta, struct No *prox);

/**
 * Libera um nó e todos os seus consecutivos.
 * Parâmetros:
 *   no - o nó a ser liberado. [ownership]
 */

void no_liberar(struct No *no);
```

Claro, isso é apenas uma possibilidade de como documentar as funções e seus
argumentos, e uma bem verbosa em particular. Mas serve bem o papel de informar a
quaisquer usuários do código (inclusive e principalmente a mim mesmo) quais as
propriedades esperadas dos argumentos e valores de retorno.
