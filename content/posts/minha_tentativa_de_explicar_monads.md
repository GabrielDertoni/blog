---
title: Minha Tentativa de Explicar _Monads_
author: Gabriel Dertoni
lang: pt-br
lang-pt: true
keywords:
- typescript
- funcional
description: Tentando explicar o que são _monads_ através de exemplos.
---

O conceito de Mônadas, ou _Monads_ é muito recorrente em programação funcional e uma das abstrações
mais poderosas do paradigma. Entretanto, entender o que essa abstração sigifica geralmente não se
mostra como uma tarefa fácil. Justamente por esse motivo, existem inúmeras tentativas de explicar
_monads_ na internet e, apesar disso, ainda é um tópico difícil de entender para novatos do
paradigma funcional.

## A falácia dos tutorias de _monad_

Um dos problemas recorrentes em tutorias que tentam explicar _monads_ se deve à falácia dos
tutorias de _monad_[^monad-tutorial-fallacy] que, em resumo, ocorre quando alguém tenta explicar
_monads_ usando uma analogia qualquer que tenha feito tudo "clicar" para si. Após ter gastado muito
tempo tentando entender o conceito, o autor finalmente entendeu e agora tudo parece tão óbvio. Se
ele somente tivesse pensando nessa analogia antes! E assim o autor prossegue a escrever sobre sua
"analogia perfeita" que, na realidade, somente funciona para si, por conta de todo o tempo que
o autor já gastou tentando entender o conceito. Por conta disso, não ajuda pessoas completamente
novas ao ele. Até virou piada comparar _monads_ a qualquer coisa, como
burritos[^monads-are-burritos], fazendo referência a esse fenômeno tão comum em tentativas de
explicar o conceito de _monad_.

Eu certamente acredito nessa falácia e já li posts e assisti palestras nos quais _monads_ são
comparados a coisas como trilhos de trem[^trains-1][^trains-2], entre outros. E o sentimento geral
que fica ao consumir esses recursos é que não captura completamente o conceito, mas tenta
demonstrar aplicações práticas de _monads_. E honestamente, isso faz muito sentido. Muitas pessoas,
assim como eu, tem dificuldade em compreender algo abstrato logo de cara. Ao invés disso,
precisamos de diversos exemplos e experiência própria para compreender por que determinadas
abstrações fazem sentido.

Do outro lado do expectro, temos os teóricos que explicam _monads_ em termos matemáticos e utilizam
teoria das categorias para suas explicações. Daí veio outra piada, "_a monad is a monoid in the
category of endofunctors, what's the problem?_"[^monad-quote] que captura esse lado insanamente
abstrato em torno do conceito de _monads_ que só pode ser compreendido por quem já compreende muito
bem todo um imenso contexto matemático. E talvez o conceito matemático, quando verdadeiramente
compreendido, realmente capture de maneira mais completa o que são _monads_. Dito isso, eu
certamente não possuo esse contexto todo matemático e entendo muito pouco dessa parte. Apesar
disso, sou capaz de pensar sobre _monads_ de maneira suficiente para entender quando são utilizados
e também criar meus próprios _monads_ de vez em quando.

Portanto, aqui vai um aviso. Eu não sou expert nem nada do tipo no assunto. Não tenho o fundamento
matemático para compreender tudo que envolve a definição de _monad_ e nem garanto que vou ser bem
sucedido em explicar _monads_ onde tantos falharam. Apesar disso, gosto de tentar explicar as
coisas que aprendo para eu mesmo entender melhor e, com sorte, de bônus conseguirei ajudar alguém!
Dito isso, vamos ao que interessa!

## Enfim, o que são _monads_

> Um _monad_ é uma forma de abstrair (controlar de maneira modularizada) a composição de operações
> que possuem algum efeito. Assim, eles escondem do usuário da abstração os detalhes específicos de
> como tratar esses "efeitos".

Primeiramente vale notar que essa é uma explicação bem centrada em programadores e não em
matemáticos. Ela foca no porquê de usar _monads_ e não em sua definição real. Nas próximas seções
vamos "descobrir" aos poucos as operações e restrições que de fato definem um _monad_ e como elas
permitem o tipo de abstração mencionada e porquê isso importa.

Provavelmente a explicação acima deixou o leitor ainda mais confuso já que ela parece vaga
e abstrata. Na realidade, para mim aprender sobre _monads_ foi um processo similar ao processo de
entender ponteiros pela primeira vez. Quando aprendemos pela primeira vez sobre ponteiros, sua
definição é muito simples "um ponteiro é um endereço de memória". Mas apesar de sua simplicidade,
parecem notavelmente difíceis de se entender, "o que significa um ponteiro de pointeiro?", "qual
a diferença de `int*` para `int`" e coisas similares. Quando finalmente entendi ponteiros tive
o meu momento "aha, ponteiros são só entedereços de memória!". Ou seja, no momento que o conceito
"clicou" para mim, a minha mente repetia exatamente a definição que antes não fazia sentido algum.
É inegável que ponteiros são fundamentais e importantes. Usamos ponteiros para construção de listas
encadeadas, árvores, grafos, ponteiros de ponteiros para matrizes, ponteiros para passagem por
referência, ponteiros para retornar mais de um valor de uma função, ponteiros para tipos abstratos
de dados, enfim, ponteiros para tudo. Similarmente _monads_ são usados para implementar variáveis
globais, mutabilidade, async/await, não determinismo, input output, exceções, goto e muitas outras
coisas em linguagens que começaram sem nada disso.

Enfim, vou tentar justificar a explicação acima com alguns exemplos e no meio através deles
explicar melhor o que eu quero dizer com "efeitos", "controlar de maneira modularizada" ou
"composição". As seções seguintes são alguns exemplos de onde podemos usar _monads_ e como os
exemplos se relaicionam com a definição. A dura realidade é que esse conceito não é simples
o suficiente para entender tudo somente com uma "analogia perfeita". Precisamos de exemplos
diversos, experiência e um pouco de sofrimento para entender.

## O Monad `Option`

Um caso particularmente simples e comum em tutorias de _monads_ é um tipo opcional. Digamos que uma
função pode ou retornar um valor, indicando uma operação bem sucedida, ou retornar outra coisa
representando que alguma falha aconteceu. Em TypeScript isso poderia ser descrito assim

```ts
function safeParseFloat(s: string): number | undefined {
    const n = parseFloat(s);
    if (isNaN(n)) return undefined;
    return n;
}
```

para melhorar um pouco o código, podemos notar que o padrão `Type | undefined` se torna uma coisa
bem comum e daí podemos criar um tipo só para isso

```ts
type Option<T> = T | undefined;

function safeParseFloat(s: string): Option<number> { /*...*/ }
```

beleza, a próxima coisa que gostaríamos de fazer é dividir dois números. Entretanto, divisão de
dois números pode dar problema se o denominador for `0`. Então só para tratar esse caso, podemos
usar nosso tipo `Option` novamente

```ts
function safeDiv(nom: number, denom: number): Option<number> {
    if (denom == 0) return undefined;
    return nom / denom;
}
```

maravilha, agora para implementar digamos, uma calculadora, queremos ler dois números fornecidos
pelo usuário como `string` e tentar dividir eles

```ts
function evalDiv(nom: string, denom: string): Option<number> {
    const optNom = safeParseFloat(nom);
    if (optNom === undefined) return undefined;
    // From now on, TypeScript knows that `optNom` is `number`.
    const optDenom = safeParseFloat(denom);
    if (optDenom === undefined) return undefined;
    // From now on, TypeScript knows that `optDenom` is `number`.
    return safeDiv(optNom, optDenom);
}
```

Ok, isso funciona. Entretanto, algo nesse código incomoda... É o fato de que temos que
constantemente fazer esse `if (variable === undefined) return undefined;` (algumas linguagens, como
Go forçam o desenvolvedor a salpicar esse tipo de coisa por todo canto). Nesse exemplo simples não
é problema, já que são só duas variáveis, mas não é difícil imaginar que para casos mais complexos,
pode ser tedioso e sujeito a falhas. A questão aqui é que a função `evalDiv`  teve que se preocupar
em tratar os casos onde as `string`s são inválidas. Mas a função `evalDiv` tem a ver com divisão,
não com tratamento de strings mal formatadas e, por isso, precisar tratar isso manualmente toda vez
é ruim. Uma forma de resolver esse problema é criar uma outra função que contém justamente essa
abstração

```ts
function andThen<A, B>(opt: Option<A>, action: (value: A) => Option<B>): Option<B> {
    if (opt === undefined) return undefined;
    // From now on, TypeScript knows that `opt` is `A`.
    return action(opt);
}
```

repare que essa função engloba justamente a abstração que estávamos mencionando e nada mais.
Reescrevendo `evalDiv` ficaria assim

```ts
function evalDiv(nom: string, denom: string): Option<number> {
    return andThen(
        safeParseFloat(nom),
        nomNumber => andThen(
            safeParseFloat(denom),
            denomNumber => safeDiv(nomNumber, denomNumber)
        )
    );
}
```

Agora sim, ignorando o `andThen`, a função `evalDiv` trata somente o que importa para ela. Mas isso
não é muito ergonômico, ter que ficar usando `andThen` o tempo todo, um dentro do outro... Talvez
possamos fazer melhor! Bem em TypeScript estamos limitados ao que a linguagem nos permite fazer,
mas vamos imaginar uma prima do TypeScript que possui uma sintaxe adicional para esse tipo de
coisa. Toda vez que a linguagem encontra uma linha do tipo

```ts
const variable <- someFunction(arg1, arg2);
/* ... rest of function body ... */
```

ela reescreve para o seguinte código TypeScript

```ts
return andThen(
    someFunction(arg1, arg2),
    variable => {
        /* ... rest of function body ... */
    }
);
```

vamos chamar essa nova linguagem de
[BetterScript](https://swc-playground-better-script.vercel.app/) (o link é uma forma simples de
traduzir essa linguagem para TypeScript). Assim, o código anterior para `evalDiv` em BetterScript
seria

```ts
function evalDiv(nom: string, denom: string): Option<number> {
    const nomNumber <- safeParseFloat(nom);
    const denomNumber <- safeParseFloat(denom);
    return safeDiv(nomNumber, denomNumber);
}
```

Muito melhor! Abstraímos completamente todo o "overhead" mental de ter que tratar erros
irrelevantes para a função `evalDiv` de maneira que ela só se preocupa exatamente com o que importa
para ela.

Com isso, acabamos de descobrir a primeira operação fundamental que todo _monad_ precisa definir,
a função `andThen`. Ela é as vezes chamada de `bind` ou sua prima `join` (que possui uma assinatura
similar mas não idêntica, mas pode ser escrita usando `andThen`). A relação dessa função com
a nossa definição inicial é que a função `andThen` é justamente uma abstração que atua sobre
a composição de operações. A "composição" aqui se refere à sequência de operações que queríamos
fazer. A função `evalDiv` queria primeiro performar `safeParseFloat(nom)` e então
`safeParseFloat(denom)` e por fim `safeDiv(nomNumber, denomNumber)` e essa sequência é o que
chamamos de composição dessas funções.

Então, até agora como vimos um _monad_ é algum tipo, no exemplo, `Option<A>` que possui uma
operação associada a ele, `andThen` que combina um valor `Option<A>` (possivelmente resultante de
outra operação) com uma operação que atua sobre esse `A` de maneira abstraída (não precisa
considerar o caso `undefined`) e essa operação pode em si retornar outra `Option<B>`. A função
`andThen` é o mecanismo fundamental que permite a composição de duas operações que possuem efeitos.
Sendo que "efeitos" se refere ao tipo `Option` em si. Ele é um efeito no sentido de que a função
`evalDiv` não se importa com `Option`, ela se importa em dividir números e, nesse sentido, `Option`
é como um "efeito colateral".

## O Monad `Result`

Um outro _monad_ muito similar ao `Option`, é o `Result`. Para entender a motivação por trás de seu
uso, digamos que a nossa calculadora está pronta mas os usuários reclamam que quando estão tentando
dividir números e ocorre algum problema, isso acarreta em `undefined` e não é nada claro qual
problema pode ter ocorrido. As vezes uma string usada não era um número válido, as vezes
o denominador era `0`, mas como em todos esses casos o resultado de `evalDiv` é `undefined` não dá
pra saber qual erro de fato ocorreu e porquê.

Para consertar isso, podemos definir um segundo tipo em BetterScript

```ts
type Result<T, E> = {
    type: "success",
    value: T,
} | {
    type: "error",
    value: E,
};
```

daí para propagar mensagens de erro nas nossas funções podemos usar `Result<number, string>`. De
maneira muito similar à `Option`, podemos definir a função `andThen`

```ts
function andThen<A, B>(result: Result<A, string>, action: (value: A) => Result<B, string>) {
    // If an error, return as is
    if (result.type === "error") return result;
    // From now on TypeScript knows that `result.type` is `"success"` and
    // that `result.value` is `A`.
    return action(result.value);
}
```

também vamos fingir que através de "mágica do compilador", quando usamos a sintaxe `const variable
<- someFunction(arg1, arg2)` ele escolhe a instância correta de `andThen` olhando pros tipos até
encontrar algo que se encaixa. Daí o resto da reescrita seria algo assim

```ts
function safeParseFloat(s: string): Result<number, string> {
    const value = parseFloat(s);
    if (isNaN(value)) {
        return {
            type: "error",
            value: "string is not a valid number"
        };
    }
    return { type: "success", value };
}

function safeDiv(nom: number, denom: number): Result<number, string> {
    if (denom === 0) {
        return {
            type: "error",
            value: "divide by zero"
        };
    }
    return {
        type: "success",
        value: nom / denom
    };
}

function evalDiv(nom: string, denom: string): Result<number, string> {
    const nomNumber <- safeParseFloat(nom);
    const denomNumber <- safeParseFloat(denom);
    return safeDiv(nomNumber, denomNumber);
}
```

Okay, talvez aqui seja um bom momento para parar e apreciar o fato de que, com exceção da anotação
de tipo (que poderia ser omitida graças a _type inference_), a definição de `evalDiv` não mudou em
nada! Esse é um dos poderes da abstração, o código se torna agnóstico à mudaças de coisas que não
importam para ele. No caso, `evalDiv` só se importa em dividir números e, portanto, modificar
o _monad_ que está propagando erros é transparente para a implementação.

## Abstraindo o conceito de _monad_

Após ver os exemplos acima, podemos notar alguns padrões em comum. Um monad é sempre algum tipo
genérico com um parâmetro (no caso `Result` possui dois argumentos, mas repare que usamos somente
`Result<T, string>`), que possui uma função `andThen`. Dessa forma, podemos extender ainda mais
a BetterScript para poder referir a esses tipos de maneira genérica. Assim, dizemos que um monad
é um tipo `M<T>` (repare que `M` pode ser qualquer tipo) que possui uma função

```ts
// Repare que `M` aqui também é um tipo genérico. Não podemos fazer isso
// em TypeScript já que não tem suporte para higher kinded types.
// Mas em BetterScritp tudo é possível!
function andThen<M, A, B>(ma: M<A>, action: (value: A) => M<B>);
```

Daí, como notamos previamente, a função `evalDiv` não se importa com o tipo de _monad_ que está
atuando, ela é agnostica a isso. Na verdade, no exemplo, quem determina se vai ser utilizado
`Option` ou `Result` são as funções que de fato se importam com isso: `safeParseFloat` e `safeDiv`.
Claro, poderíamos generalizar `evalDiv` passando essas funções como parâmetro. Isso é mais um
exercício mental e não muito prático, mas serve de base para usos mais complexos

```ts
// Aqui esse "implements" é mais como um pseudocódigo dizendo que M
// é um tipo que possui a função `andThen` apropriada.
function evalDiv<M implements Monad>(
    nom: string,
    denom: string,
    safeParseFloat: (s: string) => M<number>,
    safeDiv: (nom: number, denom: number) => M<number>
): M<number> {
    const nomNumber <- safeParseFloat(nom);
    const denomNumber <- safeParseFloat(denom);
    return safeDiv(nomNumber, denomNumber);
}
```

Isso é bem legal, mas ainda está faltando algo. Em particular, digamos que queremos implementar uma
função igualmente genérica chamada `addOne`.

```ts
function addOne<M implements Monad>(
    num: string,
    safeParseFloat: (s: string) => M<number>
): M<number> {
    const numNumber <- safeParseFloat(num);
    return numNumber + 1;
    //     ^^^^^^^^^^^^^~~~ error: has type `number`, but the function
    //                      must return a value of type `M<number>`.
}
```

o problema aqui é que na realidade precisamos também de uma outra função, vou chamá-la de `wrap`
  que encapsula um valor qualquer dentro de um _monad_.

```ts
function wrap<M, T>(value: T): M<T>;
```

Essa função é comumente chamada de `unit`, `pure`, `lift` ou `return` (sim, existe uma função com
o nome `return` em algumas linguagens funcionais onde `return` não é uma palavra reservada). Com
essa função em mãos podemos finalmente escrever `addOne` corretamente.

```ts
function addOne<M implements Monad>(
    num: string,
    safeParseFloat: (s: string) => M<number>
): M<number> {
    const numNumber <- safeParseFloat(num);
    return wrap(numNumber + 1);
}
```

Uma função adicional que geralmente é definida para monads é a chamada `map`, `fmap`, ou `select`
que faz uma projeção do tipo genérico do monad para outro tipo. Essa operação pode ser definida
completamente em termos de `andThen` e `wrap` da seguinte forma

```ts
function map<M implements Monad, A, B>(
    ma: M<A>,
    f: (value: A) => B
): M<B> {
    return andThen<M, A, B>(ma, value => wrap<M, B>(f(value)));
}
```

Numa linguagem funcional, tipos que possuem essa função `map` são chamados de _functors_ e daí
a afirmação de que todo _monad_ é também um _functor_.

## As propriedades que todo _monad_ deve ter

A única coisa que falta para uma definição mais completa de _monad_ são algumas propriedades
matemáticas que devem seguir. Isso vem do fato que _monads_ surgiram inicialmente na matemática
e somente depois foram introduzidos na computação. Além disso, essas propriedades são importantes,
pois garantem comportamentos desejados e evitam surpresas, já que podemos assumir que qualquer
monad seguirá algumas leis[^monad-laws] (como o assunto é matemática, vou escrever em LaTeX):

- Identidade à esquerda: $\text{andThen}(\text{wrap}(a), f) = f(a)$

  ```ts
  andThen(wrap(a), f) /* is the same as */ f(a)
  ```

- Identidade à direita: $\text{andThen}(m,\text{wrap}) = m$

  ```ts
  andThen(m, wrap) /* is the same as */ m
  ```

- Associatividade: $\text{andThen}(\text{andThen}(m, g), h) = \text{andThen}(m, \lambda x.\, \text{andThen}(g(x), h))$

  ```ts
  andThen(andThen(m, g), h)
  /* is the same as */
  andThen(m, x => andThen(g(x), h))
  ```

Vale notar que quando utilizo o $=$ da matemática ou "`is the same as`" significa que a computação
é exatamente equivalente e não pode ser observada qualquer diferença. E não que os valores
resultantes são iguais quando comparados com algum operador `==` ou `===`.

Então agora juntando todas as partes, um _monad_ é um tipo `M<T>` que possui duas funções:
`andThen` e `wrap` e que segue as três leis: identidade à esquerda e direita e associatividade.

### Uma pequena tangente sobre associatividade

Essa propriedade de associatividade é importante, já que garante que

```ts
function addThenDiv(num: string): Option<number> {
    // ((num + 1) / 3) / 2
    return andThen(
        addOne(num),
        num1 => andThen(
            safeDiv(num1, 3),
            num2 => safeDiv(num2, 2),
        )
    );
}
/* is the same as */
function addThenDiv(num: string): Option<number> {
    // ((num + 1) / 3) / 2
    return andThen(
        andThen(
            addOne(num),
            num1 => safeDiv(num1, 3)
        ),
        num2 => safeDiv(num2, 2)
    );
}
```

isso é importante de se notar já que algumas linguages, como Rust não possuem _monads_ diretamente,
mas em Rust existe uma função `Option::and_then` que é exatamente equivalente à operação dos
_monads_. Em Rust, você escreveria a função acima da seguinte maneira

```rust
fn add_then_div(num: &str) -> Option<f64> {
    add_one(num)
        .and_then(|num1| safe_div(num1, 3.0))
        .and_then(|num2| safe_div(num2, 2.0))
}
```

que é só _syntax sugar_ para

```rust
fn add_then_div(num: &str) -> Option<f64> {
    Option::and_then(
        Option::and_then(
            add_one(num),
            |num1| safe_div(num1, 3.0)
        ),
        |num2| safe_div(num2, 2.0)
    )
}
```

entretanto, se compararmos com a nossa BetterScript

```ts
function addThenDiv(num: string): Option<number> {
    const num1 <- addOne(num);
    const num2 <- safeDiv(num1, 3);
    return safeDiv(num2, 2);
}
```

a sintaxe especial é _syntax sugar_ para

```ts
function addThenDiv(num: string): Option<number> {
    // ((num + 1) / 3) / 2
    return andThen(
        addOne(num),
        num1 => andThen(
            safeDiv(num1, 3),
            num2 => safeDiv(num2, 2),
        )
    );
}
```

e por conta da propriedade de associatividade podemos ter certeza de que independente do _monad_,
seja `Option`, `Result` ou o que for, essas duas formas de escrever vão ser **sempre
equivalentes**.

## Mais monads, async/await em BetterScript

Passamos pelos monads mais básicos e fáceis de entender, `Option` e `Result`. Entretanto, existem
muitos outros _monads_ por aí com propriedades muito úteis. Um último exemplo que gostaria de
deixar é sobre um _monad_ bem mais complexo: o _monad_ que as vezes é chamado de `Promise` ou
`Future` e que possibilita async/await nas linguagens imperativas. De fato, esse tipo também é um
_monad_ onde as operações são definidas assim

```ts
function andThen<A, B>(promise: Promise<A>, action: (value: A) => Promise<B>): Promise<B> {
    // This is just a builtin function in TypeScript
    return promise.then(action);
}

function wrap<T>(value: T): Promise<T> {
    return Promise.resolve(value);
}
```

também precisamos garantir que as leis são cumpridas

- Identidade à esquerda

  ```ts
  andThen(wrap(a), f) /* is the same as */ f(a)
  // inlining the functions
  Promise.resolve(a).then(f) /* is the same as */ f(a) ✅
  ```

- Identidade à direita

  ```ts
  andThen(m, wrap) /* is the same as */ m
  // inlining the functions
  m.then(Promise.resolve)  /* is the same as */ m ✅
  ```
- Associatividade

  ```ts
  andThen(andThen(m, g), h)
  /* is the same as */
  andThen(m, x => andThen(g(x), h))
  // inlining the functions
  m.then(g).then(h) /* is the same as */ m.then(x => g(x).then(h)) ✅
  ```

e pronto! Está confirmado: `Promise` forma um monad com as operações `.then` e `Promise.resolve`.
Por fim, assim como em TypeScript podemos usar `async/await` para definir funções assíncronas

```ts
function sleepMS(millis: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, millis));
}

async function printHelloAfterMillis(millis: number): Promise<void> {
    await sleepMS(millis);
    console.log("hello, world");
}
```

Em BetterScript podemos fazer o mesmo sem precisamos de qualquer suporte especial da linguagem para
async/await, só usamos o que já tínhamos definido antes

```ts
function printHelloAfterMillis(millis: number): Promise<void> {
    // Valor é `void`, vamos descartar
    const _ <- sleepMS(millis);
    console.log("hello, world");
    // `wrap()` sem argumento é o mesmo que passar um argumento do tipo
    // `void`.
    return wrap();
}
```

Note que a função `printHelloAfterMillis` seria "compilada" para o equivalente do TypeScript

```ts
function printHelloAfterMillis(millis: number): Promise<void> {
    return andThen(
        sleepMS(millis),
        _ => {
            console.log("hello, world");
            return wrap();
        }
    );
}
// inlining
function printHelloAfterMillis(millis: number): Promise<void> {
    return sleepMS(millis)
        .then(_ => {
            console.log("hello, world");
            return Promise.resolve();
        });
}
```

## O _Monad_ de não determinismo

Um dos _monads_ mais legais (e já mais difíceis de compreender para mim) é o monad de lista, ou de
não determinismo. Se trata de um monad formado pelo tipo `Array` com operações

```ts
function andThen<A, B>(arr: Array<A>, action: (value: A) => Array<B>): Array<B> {
    return arr.flatMap(action);
}

function wrap<B>(value: B): Array<B> {
    return [value];
}
```

O motivo pelo qual ele também pode ser chamado de _monad_ de não determinismo é porque digamos que
você gostaria de escrever uma função que encontre um elemento dentro de uma lista de acordo com um
predicado. A forma mais intuitiva de fazer isso, é com um laço

```ts
function contains<T>(arr: Array<T>, predicate: (el: T) => boolean): boolean {
    for (const el of arr) {
        if (predicate(arr))
            return true;
    }
    return false;
}
```

mas outra forma de pensar é, ao invés de selecionar um elemento por vez e verificar, selecionar
"todos eles de uma vez" e fazer a verificação "em paralelo" de maneira não determinística. Caso
o item não seja encontrado, em uma das "execuções paralelas" produz `false` e caso tenha
encontrado, produz `true`.

```ts
function contains<T>(arr: Array<T>, predicate: (el: T) => boolean): boolean {
    function nonDet(): Array<boolean> {
        // Picks one element, but actually all of them "at once".
        // Non-determinism.
        const el <- arr;
        return wrap(predicate(el));
    }
    // Only checks if some of the "parallel executions" produced `true`
    return nonDet().some(b => b);
}
```

Outra forma de implementar a mesma ideia é não produzir valor algum quando o elemento não for
encontrado e produzir um valor qualquer (aqui usamos `{}`) quando ele é encontrado. Por fim, basta
verificar se alguma das "execuções paralelas" produziram algum valor.

```ts
function contains<T>(arr: Array<T>, predicate: (el: T) => boolean): boolean {
    function nonDet(): Array<{}> {
        const el <- arr;
        return predicate(el) ? wrap({}) : [];
    }
    // Only checks if some of the "parallel executions" produced a value
    return nonDet().length > 0;
}
```

Note que a função acima é "compilada" para

```ts
function contains<T>(arr: Array<T>, predicate: (el: T) => boolean): boolean {
    function nonDet(): Array<{}> {
        return andThen(arr, el => el == needle ? wrap({}) : [])
    }
    return nonDet().length > 0;
}
// inlining
function contains<T>(arr: Array<T>, predicate: (el: T) => boolean): boolean {
    function nonDet(): Array<{}> {
        return arr.flatMap(el => el == needle ? [{}] : [])
    }
    return nonDet().length > 0;
}
// inlining
function contains<T>(arr: Array<T>, predicate: (el: T) => boolean): boolean {
    return arr.flatMap(el => el == needle ? [{}] : []).length > 0;
}
```

Um outro exemplo onde podemos usar o não determinismo é para resolver o problema das `n` rainhas.
Esse problema, se resume em encontrar uma forma de encaixar `n` rainhas (do xadrez) num tabuleiro
`n x n` sem que nenhuma rainha esteja atacando outra. Para resolver o problema consideramos todas
as possibilidades de uma vez e computamos o resultado de maneira "linear", colocando uma rainha em
em cada linha do tabuleiro. O código ficaria

```ts
type Queen = {
    row: number,
    column: number,
};
type Solution = Array<Queen>;

function solveNQueens(n: number): Array<Solution> {
    // Solves from row `row` until row `n` having placed `placed` queens
    // on the rows prior.
    function rec(row: number, placed: Array<Queen>): Array<Solution> {
        // We reached the end, return the queens we've placed.
        if (row > n) return wrap(placed);
        // Picks one column, but actually all of them "at once".
        // Non-determinism.
        const column <- range(1, n);
        const queen = { row, column };
        return safeToPlace(placed, queen)
            ? rec(row + 1, placed + [queen])
            : [];
    }
    // Start on row 1 without any placed queens.
    return rec(1, []);
}

function safeToPlace(placed: Array<Queen>, queen: Queen): boolean {
    const attacks = (q1: Queen, q2: Queen) => (
        // same row
        q1.row === q2.row
        // same column
        || q1.column === q2.column
        // same diagonal
        || q1.row - q2.row === q1.column - q2.column
        // same other diagonal
        || q1.row - q2.row === q2.column - q1.column
    );
    // Returns `true` if no queen attacks `queen`.
    return !placed.map(q1 => attacks(q1, queen)).some();
}

// Returns an array with all integers from `start` to `end`, inclusive.
function range(start: number, end: number): Array<number> {
    const arr = [];
    // Mutation here is fine since it is confined to this function
    for (let i = start; i <= end; i++)
        arr.push(i);
    return arr;
}
```

É interessante analisar que numa máquina não determinística esse algoritmo é $O(n)$. Isso
é evidente já que a única iteração presente é na função `rec` que vai incrementando o valor de
`row` de `1` até `n`. Similarmente, a função `contains` é $O(1)$ numa máquina não determinística,
visto que não possui laços internos ou recursão.

## Conclusão

_Monads_ são uma forma de abstrair composição de operações (poderia-se até dizer, um _design
pattern_). Eles aparecem em diversas situações comuns no mundo da programação e são poderosos por
serem uma astração mínima governada por algumas propriedades matemáticas. Alguns até dizem que
_monads_ são formas de controlar o ponto e vírgula no final da declaração, já que atuam justamente
entre as operações.

Como um _design pattern_ são principalmente úteis e muito usados pelas linguagens funcionais, mas
os conceitos que envolvem também aparecem em todo tipo de linguagem de programação moderna
imperativa.

Uma percepção chave para entender que _monads_ não estão limitados a estes exemplos que mostrei,
é notar que a função `andThen` que usamos como fundação para tudo o que fizemos, recebe uma função
como segundo argumento (`action`). Por conta das regras que criamos para a sintaxe `const var <-
expr;`, essa função contém todo o resto do corpo da função. Ao invés de uma operação simplesmente
retornar, digamos, uma `Option`, isso é tratado pela `andThen` que chama `action` no valor contido
na `Option` e permite que o programa continue sua execução. Na verdade, essa função `action` na
realidade é algo que chamamos de _continuation_, uma função que encapsula o "resto" da operação.
Isso é poderoso porque a implementação de `andThen` pode determinar se/quando e com que valor
a operação vai continuar. Em _monads_ mais complexos também é possível controlar de maneira mais
fina "até onde" a operação vai continuar. Isso pode parecer meio abstrato de mais, mas um exemplo
bem prático é o `try..catch` em linguagens imperativas. Quando você coloca um bloco `try..catch`
está determinando que as exceções jogadas dentro do `try` vão retornar o fluxo para o bloco
`catch`. Nesse sentido, o `try..catch` delimita até onde exceções podem ir. No exemplo que
mostramos do `Result`, se houver uma falha em qualquer parte de qualquer função, essa falha vai ser
propagada até a função mais externa dentro do _monad_. Mas muitas vezes um controle mais fino
é necessário para implementar as lógicas que queremos, e isso também é possível através de _monads_
mais complexos (_continuation monad_).

Para fechar, _monads_ estão por toda parte, sabendo ou não disso, é um fato. Muitas linguagens
imperativas implementam _monads_ específicos como features da própria sintaxe (`async..await`,
`try..catch`, `break`, mutabilidade, etc) mas na realidade existe uma abstração única que abrange
todos esses conceitos e muitos mais: o _monad_!

## Apêndice

### Como BetterScript pode lidar com loops

Isso pode ser um questionamento entre leitores. Pode ser óbvia a forma como a reescrita de
BetterScript para TypeScript ocorreria para qualquer função sem loop. Mas se tiver loops, como
fica? Bem, na realidade, todo loop que eventualmente termina, numa linguagem imperativa requer
mutação de algum tipo. Por exemplo, num `for` loop geralmente temos um `i++` ou alguma coisa que
faz com que eventualmente a condição do loop seja `false` (se não ele roda para sempre). Num
`while` loop temos a mesma coisa, em algum momento a condição precisa ser `false`, enquanto antes
era `true` e, portanto, o corpo do loop precisa mudar algum estado para que a condição mude de
`true` para `false`. Já loops infinitos podem ser traduzidos usando recursão, eliminando
possibilidade de stack overflow através de _tail recursion_.

```ts
function infiniteLoop() {
    while (true) {
        const _ <- sleepMS(200);
        /* ... rest of body ... */
    }
}
// gets translated into
function infiniteLoop() {
    function whileLoop() {
        // tail call
        return andThen(
            sleepMS(200),
            _ => {
                /* ... rest of body ... */
                // tail call
                return whileLoop();
            }
        )
    }
    // tail call
    return whileLoop();
}
```

Se mutação for utilizada, o programa não pode mais ser considerado puramente funcional e daí se
torna bem mais complicado pensar sobre _monads_ dessa maneira como é definida em programação
funcional. Por conta disso, esses casos não estão sendo considerados. É possível até certo nível
tentar fazer esse tipo de coisa funcionar para casos específicos, como `for` loops simples

```ts
function countUntilN(n: number): Promise<void> {
    // This is also not purely functional, but it's not much of a
    // problem in this case.
    console.log(`starting with n = ${n}`);
    const _ <- sleepMS(200); // Just complicate a bit more
    // Notice that `i++` is the same as `i = i + 1`
    for (let i = 0; i < n; i++) {
        const _ <- sleepMS(200);
        console.log(`i = ${i}`);
    }
    console.log("after loop");
    return wrap();
}
// gets translated into
function countUntilN(n: number): Promise<void> {
    // tail call
    return andThen(
        sleepMS(200),
        _ => {
            function forLoop(i: number): Promise<void> {
                if (i < n) {
                    // tail call
                    return andThen(
                        sleepMS(200),
                        _ => {
                            console.log(`i = ${i}`);
                            // tail call
                            return forLoop(i + 1);
                        }
                    );
                } else {
                    // This is not present in the original code. But here
                    // we need the `forLoop` function to return something
                    // which is the value the `for` expression evaluates
                    // to, which is just void.
                    // tail call
                    return wrap();
                }
            }
            // tail call
            return andThen(
                forLoop(0),
                _ => {
                    console.log("after loop");
                    // tail call
                    return wrap();
                }
            );
        }
    );
}
```

e também para `for...of` que são mais restritos e não requerem do usuário fazer a mutação
manualmente (ela existe, entretanto, já que a variável escondida que armazena o objeto de iterador
é modificado a cada iteração).

```ts
function printElements(arr: Array<number>): Promise<void> {
    for (const el of arr) {
        const _ <- sleepMS(200);
        console.log(el);
    }
    return wrap();
}
// gets translated into
function printElements(arr: Array<number>): Promise<void> {
    const arr_it = arr[Symbol.iterator]();
    function forLoop() {
        // Here is the mutation, `.next()` mutates the `arr_it` object.
        const { value: el, done } = arr_it.next();
        if (!done) {
            return andThen(
                sleepMS(200),
                _ => {
                    console.log(el);
                    return forLoop();
                }
            );
        } else {
            return wrap();
        }
    }
    return andThen(
        forLoop(),
        _ => {
            return wrap();
        }
    );
}
```

Entretanto note que um `for...of` como em `printElements` não funcionaria para _monads_ que chamam
a _continuation_ mais de uma vez, como é o caso do _monad_ de não determinismo uma vez que o objeto
de iterador foi modificado uma vez e não tem como "voltar atrás". Portanto, mutação não é uma coisa
que pode ser tratada tão facilmente de maneira geral.

### Transformação passo-a-passo

Só uma sugestão de como essa transformação poderia de fato ser potencialmente implementada

```ts
function countUntilN(n: number): Promise<void> {
    console.log(`starting with n = ${n}`);
    const _ <- sleepMS(200);
    for (let i = 0; i < n; i++) {
        const _ <- sleepMS(200);
        console.log(`i = ${i}`);
    }
    console.log("after loop");
    return wrap();
}
// step 1: transform loops
function countUntilN(n: number): Promise<void> {
    console.log(`starting with n = ${n}`);
    const _ <- sleepMS(200);
    function forLoop(i = 0 /* allows type inference */) {
        if (i < n) {
            const _ <- sleepMS(200);
            console.log(`i = ${i}`);
            // Mutation is fine here, its just easier to reuse existing
            // code.
            i++;
            return forLoop(i);
        } else {
            return wrap();
        }
    }
    _ <- forLoop();
    console.log("after loop");
    return wrap();
}
// step 2: transform `const variable <- expr;`
function countUntilN(n: number): Promise<void> {
    console.log(`starting with n = ${n}`);
    return andThen(
        sleepMS(200),
        _ => {
            function forLoop(i = 0 /* allows type inference */) {
                if (i < n) {
                    return andThen(
                        sleepMS(200),
                        _ => {
                            console.log(`i = ${i}`);
                            i++;
                            return forLoop(i);
                        }
                    );
                } else {
                    return wrap();
                }
            }
            return andThen(
                forLoop(),
                _ => {
                    console.log("after loop");
                    return wrap();
                }
            );
        }
    );
}
```

[^monad-tutorial-fallacy]: [Abstraction, intuition, and the “monad tutorial fallacy”](https://byorgey.wordpress.com/2009/01/12/abstraction-intuition-and-the-monad-tutorial-fallacy/)

[^monads-are-burritos]: [Monads are like burritos](https://blog.plover.com/prog/burritos.html)

[^trains-1]: [Monadic Error Handling in Python](https://www.youtube.com/watch?v=J-HWmoTKhC8&t=527s)

[^trains-2]: [Functional Design Patterns](https://www.youtube.com/watch?v=srQt1NAHYC0&t=1101s&ab_channel=NDCConferences)

[^monad-quote]: [A Brief, Incomplete, and Mostly Wrong History of Programming Languages](http://james-iry.blogspot.com/2009/05/brief-incomplete-and-mostly-wrong.html)

    [Contexto adicional](https://stackoverflow.com/questions/3870088/a-monad-is-just-a-monoid-in-the-category-of-endofunctors-whats-the-problem)

[^monad-laws]: [Monad laws](https://wiki.haskell.org/Monad_laws)
