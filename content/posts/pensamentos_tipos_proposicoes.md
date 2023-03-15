---
title: Pensamentos Sobre Tipos Como Proposições
author: Gabriel Dertoni
lang: pt-br
lang-pt: true
keywords:
- haskell
- functional
description: Pensamentos sobre tipos como proposições e programas como provas.
---

## Introdução

Uma coisa interessante que descobri sobre programação funcional é sobre a relação entre tipos e proposições matemáticas e entre programas e provas matemáticas. Essa relação é chamada de _Curry-Howard Isomorphism_ aparentemente. Eu ainda estou começando a estudar sobre isso, mas o tópico já é imediatamente interessante! Posto de maneira simples, isso significa que uma função de um programa é, na verdade uma prova matemática sobre alguma coisa. Na realidade, isso não é verdade de maneira geral para todos os programas. Mas pelo menos para funções puras, isso é verdade.

Nesse modelo de pensar, os tipos se comportam como proposições e as definições como provas. Ou seja, se alguém te mostra que a assinatura de determinada função é

```haskell
aBool :: Bool
aBool = {- ... alguma coisa ... -}
```

isso é uma prova de que a proposição `Bool` é "verdadeira". Mas o que isso significa? Significa que é um tipo habitado. Isto é, existe um valor de tempo de execução para esse tipo. O valor é chamado de "habitante" do tipo. Isso pode parecer estranho, já que não estamos considerando qual dos habitantes do tipo (`True` ou `False`), somente estamos afirmando que "ele precisa ser habitado pelo simples fato de que alguém foi capaz de escrever essa implementação". Nesse sentido, a implementação da função é a prova da proposição, desde que sejamos capazes de escrever essa implementação.

```haskell
-- Aqui está uma prova possível
aBool = False

-- Aqui está outra prova possível
aBool = True
```

Vendo dessa forma, funções atuam exatamente como "$\rightarrow$" na matemática, ou seja, `a -> b` significa que, providenciado um prova para `a`, é possível obter uma prova para `b`. Além disso, podem haver outras maneiras de provar `b`, independente de existir uma prova para `a`. Por exemplo

```haskell
data PEqualsNP = {- Só é possível instanciar se P = NP -}

ifThen :: PEqualsNP -> ()
ifThen p_equals_np = ()

easierProof :: ()
easierProof = ()
```

nesse caso imaginei um tipo hipotético de algo muito difícil ou impossível provar, $P = NP$ e, a partir disso, podemos provar `()`. Mas também é possível provar `()` de outra forma muito mais fácil. Apesar disso, poderiam ter coisas mais interessantes, como

```haskell
optimize :: (PEqualsNP, SomeNPProblem) -> PolynomialAlgorithm
optimize (p_equals_np, problem) = {- usa a prova de alguma forma -}
```

ou seja, dado uma prova $P = NP$ e algum problema qualquer dentro da classe $NP$ seria possível gerar um algoritmo que resolve o problema em tempo polinomial. Aqui já é possível verificar ainda outra forma de combinar provas, com tuplas! De fato, a prova de $A \land B$ é representada por `(A, B)`. Similarmente, a prova de $A \lor B$ é representada por `Either A B`. Isso é bem natural, já que `(,)` é a essência do tipo produto e `Either` a essência do tipo soma.

A partir disso, podemos definir algumas coisas para deixar nossa programação mais parecida com a matemática sintaticamente

```haskell
type a /\ b = (a, b)
type a \/ b = Either a b
```

Como vimos anteriormente, para provar que algo é verdadeiro, precisamos ser capazes de escrever a definição da função. Nesse sentido, a proposição mais fácil de provar seria justamente `()`, já que possui um único habitante (valor possível). Também é possível definir uma função única

```haskell
constUnit :: forall a. a -> ()
constUnit _ = ()
```

Ou seja, `()` de certa forma representa a "essência" do que é verdadeiro já que para qualquer tipo `A` habitado, ao obter um habitante do tipo `a :: A` podemos simplesmente usar `constUnit a` para obter `()`. Isso é interessante pois de fato existe um oposto ao tipo `()`, o tipo `Void`.

## Uma tangente sobre o tipo `Void`

Apesar desse nome "void" ser usado em muitas linguagens de programação imperativas, ele geralmente representa o tipo unitário `()`. Isso é bem contraintuitivo pois nessas linguagens `void` significa que a função não retorna valor. Mas isso é uma completa mentira. É claro que retorna! Ela retorna o único habitante do tipo `void`. Por exemplo, por um momento esqueça todos os efeitos colaterais da linguagem C. Qual a diferença entre essas duas funções?

```c
typedef struct {} unit_t;

uinit_t f() { return (unit_t){}; }
void    g() { return;            }
```

Uma delas retorna `unit_t` e a outra `void`. Existe somente uma forma de construir `unit_t` uma vez que é um struct vazio que possui `0` bytes de tamanho (ao menos conceitualmente). Similarmente, existe uma única forma de retornar da função `g`. O confuso é que em C, por qualquer motivo, as coisas são estranhas

```c
unit_t var_f = f(); // Ok
void   var_g = g(); // Erro de compilação
```

apesar disso, não é difícil perceber que `f` e `g` são completamente equivalentes (isomórficas) e absolutamente qualquer função que retorna `void` poderia ser refatorada para retornar `unit_t` e vice-versa, sem qualquer perda, uma vez que é impossível diferenciar duas instâncias de `unit_t` assim como é impossível diferenciar dois `void`s.

> [!NOTE]
> Aparentemente o _standard_ do C não permite tipos com tamanho `0`, mas o argumento ainda é válido! Mas esse fato dá sentido ao fato do tipo `void` não poder ser guardado numa variável.

Depois da imensa e absoluta popularização e adoção do C, muitas das linguagens que seguiram a mesma linha (como Java e C#) copiaram essa noção de `void`. Apesar disso, linguagens interpretadas, como Python ou Javascript possuem sim tipos unitários que podem ser armazenados em variáveis. Isso porque é possível escrever algo como

```python
v = f()
```

que declara a variável `f` e portanto ela precisa ter um valor. No Python esse valor é o `None` e no Javascript é o `undefined`. Além disso, linguagens mais modernas como Rust ou Zig possuem tipos unitários, `()` e `void` respectivamente. Mas o `void` do Zig é realmente um tipo unitário que você pode armazenar em uma variável ou numa lista e não a estranhisse que é em C.

Mas o `Void` a que estou me referindo não é nenhum desses valores, na verdade muito pelo contrário! Quando falamos do tipo `Void` em programação funcional estamos nos referindo a um tipo que não pode ser construído. Ou seja, ele é um tipo inabitado. Esse tipo que justamente não pode ser manipulado em tempo de execução é na realidade muito útil e usado em algumas linguagens de programação fora do espectro funcional. Por exemplo, Zig e Rust chamam esse tipo `noreturn` e `never` (ou `!`) respectivamente. Ele é um tipo muito útil principalmente para linguagens baseadas em expressões. Em haskell e outras linguagens funcionais esse tipo se chama `Void` e é definido assim

```haskell
data Void
```

Repare que não há `=` após a definição do tipo já que ele não possui construtores. Esse tipo que não possui habitantes é a representação do falso. Provar algo falso é impossível e equivalente a construir o tipo `Void` (que também é impossível). Esse tipo possui algumas propriedades interessantes:

- `Void /\ ()` não possui habitantes, equivalente a $False \land True = False$
- `Void \/ ()` possui exatamente um habitante, equivalente a $False \lor True = True$

Além disso, a partir de algo falso, é possível provar qualquer coisa (_ex falso quodlibet_, do Latim, "a partir da falsidade, qualquer coisa")

```haskell
absurd :: Void -> a
absurd unobtainable = undefined {- impossível chegar aqui -}
```

Essa propriedade é bastante usada em Rust por exemplo, vejamos um exemplo de código

```rust
fn f(b: bool) -> Result<(), char> {
    let unit = match b {
        true => (),
        false => return Err('a'),
    };
    Ok(unit)
}
```

de maneira geral todos os casos do `match` precisam possuir o mesmo tipo. De fato, se eu remover o `return` dali, vai dar erro de compilação já que `true => ()` possui tipo `()` e daí `false => Err('a')` possuiria tipo `Result<_, char>`. Entretanto ao invés disso tem um `return` que faz com que o fluxo de controle saia da função inteira. Portanto, o tipo da expressão `return Err('a');` é o nosso tipo `Void` que em Rust se chama `!` ou `never`. Nesse caso ele fez uma conversão implícita de `!` para `()`. Keywords como `continue` e `break` possuem o mesmo comportamento. Para deixar isso ainda mais óbvio, podemos usar uma feature flag `never_type` (já que essa feature está no nightly atualmente) para poder escrever o tipo `!` explicitamente

```rust
#![feature(never_type)]

fn g<A>() -> Result<A, ()> {
    let impossible: ! = return Err(());
    let anything: A = impossible;
    return Ok(anything);
}
```

o compilador vai gritar um monte de warning (esse código é bem estúpido), mas nenhum erro. O compilador vai simplesmente usar essa função `absurd` implicitamente (conceitualmente) para transformar algo do tipo `!` em algo de qualquer tipo.

## De volta à lógica, negação e igualdade

Ainda mais interessante, é possível definir negação lógica como

```haskell
type Not a = a -> Void
```

Ou seja, dado uma prova de `a` é possível chegar em `Void`, portanto `a` precisa ser falso.

Para provar que `a = b` vamos precisar usar uma extenção do Haskell chamada "GADT", que significa _Generic Algebraic Data Type_ e nos permite definir tipos de maneira mais específica, permitindo os construtores de um tipo possuírem genéricos mais restritos que o todo. É meio difícil explicar, melhor mostrar!

```haskell
data Equal a b where
    Refl :: Equal a a

type a :~: b = Equal a b
```

aqui o tipo se chama `Equal` e possui dois tipos genéricos `a` e `b`. Além disso ele possui somente um construtor, `Refl` (o nome vem de "reflection"). Só que o tipo do construtor `Refl` é na verdade `Equal a a`. Uma coisa importante de notar é que a variável de tipo `a` usada na linha do `data Equal a a where` **não é a mesma** da que é usada na linha `Refl :: Equal a a`. Na realidade são variáveis distintas e poderiam ter nomes distintos (mas sempre é definido dessa forma, por isso fiz igual). Isso me confundiu muito inicialmente! Basicamente o poder do tipo `Equal` é que só podemos construir ele se de fato os dois tipos genéricos forem iguais. Por exemplo

```haskell
simpleEquality :: () :~: () -- Equivalente a `Equal () ()`
simpleEquality = Refl -- Temos que de fato () = () e portanto isso é OK
```

Em Haskell a igualdade de tipos é representada por `~` e é como se fosse uma typeclass, só que ela é _builtin_. Quando aparece um `a ~ b` no código é uma _constraint_ indicando que o tipo `a = b`. Isso é muito usado no _typechecker_ já que ele precisa constantemente testar se os tipos são iguais ou não. Portanto, quando fazemos algo como

```haskell
notEqual :: () :~: Void
notEqual = Refl -- Único construtor que podemos usar
```

o compilador reclama que

```txt
• Couldn't match type ‘()’ with ‘Void’
      Expected: () :~: Void
        Actual: () :~: ()
```

Ou seja, podemos escrever o tipo `() :~: Void` sem nenhum problema, mas não será possível construir um habitante desse tipo, já que o construtor requer que ambos os tipos genéricos sejam o mesmo. Nesse caso, o compilador tentou resolver a `() ~ Void` e não conseguiu encontrar solução e por isso ele acusa o erro.

Outra coisa importante é que quando temos uma função que usa `a :~: b` como parâmetro e fazemos pattern match com `Refl` o compilador anota que `a ~ b` uma vez que é a única forma daquele construtor ter sido criado. Com isso, podemos definir algumas operações com igualdade.

```haskell
-- Propriedade simétrica da igualdade
-- forall a b, a = b <-> b = a
sym :: forall a b. (a :~: b) -> (b :~: a)
sym Refl = Refl -- Como `a ~ b`, podemos usar um no lugar do outro
--  ^^^^~~~ pattern match faz compilador perceber que `a ~ b`
--
-- Note que `sym proof = Refl` não funcionaria já que não demos match
-- no construtor, o compilador não consegue concluir `a ~ b`

-- Propriedade transitiva da igualdade
-- forall a b c, (a = b /\ b = c) -> a = c
trans :: forall a b c. (a :~: b) -> (b :~: c) -> (a :~: c)
trans Refl Refl = Refl

-- forall a b, (a = b /\ a) -> b
castWith :: forall a b. (a :~: b) -> a -> b
castWith Refl = id -- Podemos usar a função identidade, já que aqui
                   -- o compilador sabe que `a ~ b`.

apply :: forall f g a b. (f :~: g) -> (a :~: b) -> (f a :~: g b)
apply Refl Refl = Refl

-- Um exemplo de como essas funções podem ser combinadas para criar
-- novas provas. Poderia ser definido de maneira mais simples também.
replace :: forall a b f. (a :~: b) -> f a -> f b
replace proof fa = castWith (apply Refl proof) fa
--                 f a :~: f a ~~~~^^^^ ^^^^^~~~ a :~: b 
```

## Kinds

Para entender o código que vamos escrever mais à frente, é necessario ainda falar sobre o conceito de _kind_. Assim como valores em haskell possuem tipos, os tipos possuem _kinds_. Vou escrever em inglês mesmo já que a tradução de "kind" seria "tipo" e acho que já deu pra entender o problema. Por curiosidade, o que está acima dos _kinds_ é o _sort_ (que também seria traduzido para "tipo"), mas Haskell para aí, não há nada acima dos _sorts_ e só existe um sort chamado `BOX` mas ninguém liga pra ele (nem tem como se referir a ele na linguagem). Em linguagens com suporte completo a tipos dependentes, como Idris ou Agda, isso vai ao infinito! De qualquer maneira, o _kind_ é o tipo do tipo. Pode parecer meio assustador, mas na verdade você já viu vários _kinds_ só nesse texto! Por exemplo, numa função de `Char -> Bool` por exemplo, usamos essa setinha "`->`" para separar o tipo do argumento do tipo de retorno, ela possui kind

```haskell
-- Isso é uma anotaçào de kind
type (->) :: Type -> Type -> Type
--                ^^~~~ sim, outra "->", mas não é a mesma, isso é um
--                      construtor de kind

-- Ou seja, o kind de "->" é algo que toma dois tipos como argumento
-- e retorna outro tipo

-- O kind do `Either` é o mesmo da "->", mas assim como o mesmo tipo
-- pode possuir valores completamente distintos, o mesmo kind pode
-- possuir tipos muito diferentes.
type Either :: Type -> Type -> Type

-- Typeclasses também possuem kinds! Entretanto, ao invés de "retornar"
-- um tipo, ele "retorna" uma `Constraint`.
type Num :: Type -> Constraint

type Int :: Type -- O kind do `Int` é simplesmente um tipo
```

Esse tipo de coisa você consegue ver no `ghci` com `:info (->)`, ou simplesmente `:i (->)`. Para ficar mais legível eu recomendo rodar o comando `:set -XNoStarIsType` e `:set -fprint-explicit-foralls` (mais útil ainda quando usando `TypeApplications`). Para ver só o _kind_ de algo, sem informações extras no `ghci`, existe o comando `:kind (->)` e equivalentemente `:k (->)` para isso.

## Mais algo sobre `GADTs`

Uma outra coisa que me custou pra entender na sintaxe dos GADTs é que quando queremos um GADT que guarda algum dado dentro dele, usamos uma sintaxe peculiar. Ela faz bastante sentido depois que você se acostuma, mas inicialmente me foi muito confuso.

```haskell
data List a where
    Nil  :: List a
    Cons :: a -> List a -> List a

-- Exatamente equivalente à seguinte definição sem a sintaxe dos GADTs
-- data List a = Nil | Cons a (List a)
```

a setinha ali na linha `Cons :: a -> List a -> List a` na realidade indica que dentro do construtor `Cons` serão armazenados duas coisas, uma do tipo `a` e outra do tipo `List a`. De fato, o construtor `Cons` terá esse tipo se inspecionado `:t Cons` no `ghci`. Mas para mim foi meio contraintuitivo pensar nessa sintaxe de função na definição do construtor. Tudo que importa aqui é que o construtor `Cons` vai armazenar essas duas coisas dentro e nessa ordem. Se estivermos fazendo pattern match no cons usamos `Cons head tail` e então os tipos serão `head :: a` e `tail :: List a`.

## Um pouco de prática

Ok, chega de teoria, vamos tentar provar algo com isso! Aplicar esse conceito em programas reais envolve criar tipos que encapsulam mais informações sobre as propriedades que eles possuem. Um exemplo é o tipo `NonEmpty` do Haskell que representa uma lista não vazia. Obter um habitante do tipo `NonEmpty` é uma prova de que a lista é não vazia. De qualquer maneira, vamos tentar provar algo um pouco mais interessante, que

$$\forall n \in \mathbb{N},\, \neg (n + 1 = 0)$$

ou seja, que $n + 1 \neq 0$.

```haskell
{-# LANGUAGE GADTs, DataKinds #-}

import Data.Kind

data Void

type Not a  = a -> Void

-- Representação dos números naturais
-- A extenção `DataKinds` nos permite usar `Nat` também no nível de kind.
-- Dessa forma, os construtores `Z` e `S` possuem kind `Nat`.
data Nat = Z | S Nat

data a :~: b where
    Refl :: a :~: a

-- se a = b, então f a = f b, portanto dado f a podemos
-- obter um f b (já que são iguais)
replace :: forall k (a :: k) (b :: k) (f :: k -> Type).
           a :~: b -> f a -> f b
replace Refl = id

type F :: Nat -> Type
data F a where
    -- Construímos esse cara aqui, mas como temos uma prova
    -- que `Z ~ S n`, podemos provar que `F Z ~ F (S n)` e
    -- assim obter o outro construtor.
    CaseZ :: ()   -> F Z
    -- Não dá pra construir esse tipo diretamente
    CaseS :: Void -> F (S n)

succ_neq_z :: forall (n :: Nat). Not (Z :~: S n)
succ_neq_z proof = case replace proof (CaseZ ()) of
                     CaseS void -> void
                     -- Não há mais casos para testar uma vez que o
                     -- compilador sabe que o tipo aqui é `F (S n)`
                     -- e portanto o único construtor possível é
                     -- `CaseS`.
```

Na realidade, usando o tipo `Nat` builtin do GHC, é possível escrever esse código de maneira bem mais legível e concisa. Aqui está o programa inteiro

```haskell
{-# LANGUAGE GADTs, DataKinds, TypeFamilies, TypeApplications #-}

import GHC.TypeLits
import Data.Kind
import Data.Type.Equality
import Data.Void

type Not a  = a -> Void

type F :: Nat -> Type
data F a where
    CaseZ :: ()   -> F 0
    CaseS :: Void -> F (n + 1)

succ_neq_z :: forall (n :: Nat). Not (0 :~: n + 1)
succ_neq_z proof = case castWith (apply Refl proof) (CaseZ ()) of
                     CaseS void -> void
```

O mais legal disso é que não precisamos rodar o programa. Se ele compila, já é prova de que, de fato $\forall n \in \mathbb{N},\, 0 \neq n + 1$.

## Recursos
- [Palestra "Propostitions as Types" da Strange Loop, 2015](https://www.youtube.com/watch?v=IOiZatlZtGU&t=2037s)
- [Blog post "Intuitionistic logic in Haskell"](https://ivanbakel.github.io/posts/intuitionistic-logic-in-haskell/#:~:text=Intuitionistic%20logic%20is%20precisely%20what,have%20no%20equivalent%20intuitionistic%20proof.)
- [Haskell wiki "The Curry-Howard isomorphism"](https://en.wikibooks.org/wiki/Haskell/The_Curry%E2%80%93Howard_isomorphism)
- [Curso da UFABC "Desenvolvimento Orientado a Tipos"](https://haskell.pesquisa.ufabc.edu.br/desenvolvimento-orientado-a-tipos/)
