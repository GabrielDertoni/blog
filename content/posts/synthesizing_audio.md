---
title: Sintetizando Áudio com Programação Funcional Reativa
author: Gabriel Dertoni
lang: pt-br
lang-pt: true
description: Sintetizando áudio usando a progamação funcional reativa e descobrindo como áudio funciona nos computadores.
keywords:
- haskell
- audio
- functional
---

## Introdução à Programação Funcional Reativa

Recentemente me deparei com o conceito de Programação Funcional Reativa (_Functional Reactive Programming (FRP)_), sendo um amador do paradigma funcional, resolvi pesquisar mais sobre o que seria isso e me deparei com [uma palestra](https://www.youtube.com/watch?v=rfmkzp76M4M&t=1546s) do criador desse conceito, Conal Elliott. Se trata de uma palestra excelente que recomendaria a todos interessados mais no assunto. Entretanto, correndo o risco de fazer simplificações grosseiras, vou tentar resumir. Na palestra, o autor descreve a PRF como duas coisas centrais

- Notação simples e precisa (elegante e rigorosa)
- Tempo contínuo (natural e combinável)

A semântica dessa nova forma de pensar sobre programas é composta de coisas que Conal chama de comportamentos (_behaviours_) que seria análogo a uma função a partir do tempo. Dessa forma, poderiamos considerar

```haskell
type Behaviour a = Time -> a
```

De acordo com Conal, é importante separar de maneira bem clara a semântica do que se está tentando fazer dos detalhes de implementação. Nese sentido, poderíamos imaginar que um _behaviour_ na realidade é somente análogo (ou isomórfico) a uma função a partir do tempo. Aqui também vale notar que o tempo é contínuo e não discreto. De fato, esse valor de tempo poderia ser representado por um valor real

```haskell
type Time = R;
```

com esse conceito, já podemos perceber algumas formas de combinar _behaviours_ para criar novos, por exemplo

```haskell
-- Um comportamento que retorna o tempo atual
time :: Behaviour Time
time t = t
-- time = id -- Análogo à função identidade

-- Um comportamento que recebe um valor e retorna ele
-- para qualquer tempo. Ou seja, define uma constante
-- no tempo.
lift0 :: a -> Behaviour a
lift0 val t = val
-- lift0 = const -- Análogo à função const

-- Dado uma função de a para b, transforma cada valor
-- de um behaviour com a função
lift1 :: (a -> b) -> Behaviour a -> Behaviour b
lift1 f behaviour t = f (behaviour t)
-- lift1 = fmap -- Análogo à função fmap

lift2 :: (a -> b -> c) -> Behaviour a -> Behaviour b -> Behaviour c
lift2 f behaviourA behaviourB t = f (behaviourA t) (behaviourB t)
-- lift2 = liftA2 -- Análogo à função liftA2

timeTrans :: Behaviour a -> Behaviour Time -> Behaviour a
timeTrans behaviourA behaviourT t = behaviourA (behaviourT t)
-- timeTrans = (.) -- Análogo à função (.)

-- Essa é legal! Poderia ser implementado usando o método
-- Runge-Kutta, mas não será o foco
integral :: VectorSpace a => Behaviour a -> Time -> Behaviour a

instance Num a => Num (Behaviour a) where
    (+) = lift2 (+)
    (-) = lift2 (-)
    (*) = lift2 (*)
    negate = lift1 negate
    abs = lift1 negate
    signum = lift1 signum
    fromInteger = lift0 . fromInteger
```

Aqui já estou mostrando algumas das formas de implementar essas funções, mas o que mais importa é o que elas fazem. Seria possível modificar a implementação sem mudar o comportamento.

## Aplicando PFR para síntese de áudio

Ao ver tudo isso, fiquei imediatamente pensando em como eu poderia implementar esses novos conceitos em algum programa. E foi aí que surgiu uma boa ideia! Uma função de tempo para um valor... Podemos usar isso para gerar música! Ora, na realidade a música é feita de ondas sonoras a uma onda sonora pode ser facilmente descrita como uma função do tempo para o valor da onda naquele momento. Tome como exemplo a função $sen(t)$, ela vai gerar justamente uma onda com alguma frequência. Sabemos que para a função seno completar um ciclo, é necessário um intervalo de $2\pi$ em $t$. Portanto, se considerarmos que $t$ é medido em segundos e quisermos que a função faça $440$ ciclos em um segundo (a nota Lá padrão de 440 Hz), basta multiplicar! Assim, podemos definir um behaviour para gera a nota Lá:

[Imagem da onda senoidal]

```haskell
standardA440 :: Behaviour Float
standradA440 t = sin (2 * π * 440 * t)
```

Com essa função devemos ser capazes de extrair a forma de onda necessária para produzir a nota que queremos. Mas para isso, é necessário entender um pouco como funciona o áudio digital. Quando utilizamos o áudio analógico, a onda sonora primeiro existe em formato de onda elétrica. É uma variação da corrente elétrica que representa exatamente determinada onda sonora (ela é análoga às ondas sonoras, por isso chamamos de sistemas analógicos). Na hora de reproduzir o som, essa corrente elétrica é utilizada para mover a membrana da caixa de som na frequência em que varia, assim produzindo o som. Entretanto, no mundo digital, não temos o luxo de utilizar os infinitos valores que a corrente elétrica pode assumir, temos que nos contentar com zeros e uns! Por conta disso, não é possível armazenar perfeitamente o formato da onda em som digital, o melhor que se pode fazer é aproximar. Para fazer isso, guardamos somenta algumas amostras da onda original, a taxa no qual essa amostragem ocorre é convenientemente chamada de "taxa de amostragem" ou _sample rate_. Além disso, cada amostra é armazenada como um número binário e a quantidade de bits desse número é chamado de _bit rate_. Uma das formas de amostrar uma onda é com valores `Float` $\in [-1, 1]$, sendo que $-1$ é o menor valor possível e $1$ o maior.

[Imagem da amostragem]

Uma coisa interessante de se notar é que a nossa função `standardA440`, em princípio é como uma onda perfeita. Podemos ler o valor da onda em qualquer momento e, como ainda não definimos o tipo binário que utilizaremos para medir o tempo, poderíamos imaginar que ela representa toda a informação da onda! Ou seja, essa forma de representar uma onda não possui perdas de discretização do tempo, assim como os sinais digitais típicos possuem. Para mim, esse é o real poder da programação funcional reativa! Ela te permite definir comportamentos com "resolução infinita". Sim, a memória dos computadores não é infinita e eventualmente isso terá que ser discretizado de alguma forma, mas atrasar isso o máximo é muito poderoso e permite facilmente implementar programas que poderiam ser mais complexos se feitos da maneira imperativa. Apesar disso, para o resto desse texto, vou definir

```haskell
type Time = Float
```

## Tocando sons

Enfim, de qualquer maneira, se quisermos tocar esse som num hardware digital, precisamos discrezar ele. Ou seja, temos que amostrar a nossa onda com algum _sample rate_ e então tocar isso de alguma forma. Como um _behaviour_ é simplesmente uma função a partir do tempo, podemos só aplicar ela numa lista com os tempos das amostras.

```haskell
sampleRate = 48000

-- Amostragem de 2 segundos de áudio
samples :: [Float]
samples = fmap standardA440 [0.0, 1.0 / sampleRate, .. 2.0]
```

Para escrever isso para um arquivo que pode ser tocado, podemos serializar os valores `Float` para o formato little-endian e escrevê-los um atrás do outro num arquivo. Sim, é tão simples quanto isso! Para fazer isso em Haskell, vou usar o pacote `bytestring` que permite manipular bytes.

```haskell
import qualified Data.ByteString.Builder as Bytes

toBytesBuilder :: [Float] -> Bytes.Builder
toBytesBuilder = foldMap Bytes.floatLE

main :: IO ()
main = Bytes.writeFile "sound.bin" (toBytesBuilder samples)
```

A única questão agora é que o arquivo que geramos é um arquivo binário _RAW_, ou seja, não possui metadados que indiquem o formato dele. Portanto, para poder ouvir ao som, precisamos usar algo como o Audacity, ou `ffplay` (linha de comando) que permitem tocar arquivos _RAW_ de som. Para usar o Audacity, basta ir em `Arquivo > Importar > Arquivo Sem Formatação (RAW)` e daí selecionar as opções corretas (vai pedir o sample rate e o formato). Para usar o `ffplay` podemos rodar o seguinte comando `ffplay -f f32le -ar 48000 sound.bin`.

## Mais sons

O Lá 440Hz é um padrão sobre o qual todas as outras notas são definidas. Para obter as outras notas, basta passar o número de semitons acima ou abaixo do Lá 440Hz. Como o foco aqui não é entender o porquê das coisas da música e como não sou músico, vou só mostrar a formula pronta:

```haskell
-- Transforma o tempo para ir x vezes mais rápido
-- nessa implementação também é possível ver como é possível
-- combinar diferentes funções para produzir código simples
-- e legível.
timesFaster :: Float -> Behaviour Time
timesFaster x = const x * time

-- Aqui usamos o `timeTrans` para transformar o tempo da função
-- standardA440. Se o tempo passa mais rápido para essa função,
-- a onda produzida resultante terá uma frequência maior.
semitonesUp :: Float -> Behaviour Float
semitonesUP n = timeTrans standardA440 (timesFaster (a ** n))
    where -- número mágico, pergunte a um músico
          a = 2.0 ** (1.0 / 12.0)
```

Então agora, podemos tentar gerar um som que toca primeiro uma nota e depois outra. Mais pra frente veremos que há uma forma melhor de fazer isso, mas por agora podemos amostrar primeiro a primeira nota, depois a segunda e depois juntar as duas.

```haskell
samples :: [Float]
samples = tone1Samples ++ tone2Samples -- Concatena
    where tone1Samples = fmap tone2 sampleTimes -- Um Lá
          tone2Samples = fmap tone1 sampleTimes -- Um Sí

          tone1 = semitonesUp 0
          tone2 = semitonesUp 2

          sampleTimes1 = [0.0, 1.0/sampleRate .. 1.0]
          sampleTimes2 = [1.0, 1.0 + 1.0/sampleRate .. 2.0]
```

Se tocarmos esse som, entretanto, será bem notável algo que já era possível perceber antes. Quando o som começa ou as notas trocam, há um clipe, um barulho que acontece bem nesses momentos. O motivo pelo qual isso acontece, é que a caixa de som não consegue instantâneamente mudar de um som para outro. Ela precisa de uma transição. Na realidade, quando estamos falando de música sintetizada, geralmente quando se quer modelar o toque de uma nota em algum instrumentos, a onda dessa nota é colocada dentro de um envelope. Esse envelope controla o volume da nota em 4 etapas, _attack_, _decay_, _sustain_ e _release_. A imagem abaixo explica melhor como isso funciona.

[Imagem envelope]

O envelope faz com que, quando a nota é tocada ela vai além do nível normal dela o que seria equivalente a quando alguém aperta a tecla do piano e o martelo bate na corda. Esse som é inicialmente mais alto, mas depois decai um pouco até que chega num nível onde ele se mantém enquanto a pessoa estiver, digamos, segurando a tecla do piano. Finalmente, quando a tecla é soltada, a nota decai já que os abafadores encostam nas cordas. A nota não surge ou decai instantâneamente e é isso que temos que modelar a seguir!

```haskell
type Duration = Float
type Volume = Float

data Envelope = Envelope { _attackDuration :: Duration
                         , _decayDuration :: Duration
                         , _sustainLevel :: Volume
                         , _releaseDuration :: Duration
                         }

-- Recebe um valor `t` entre [0, 1] e retorna um valor
-- entre [lo, hi] interpolado linearmente
lerp :: Num a => a -> a -> a -> a
lerp t lo hi = lo + (hi - lo) * t

mute :: Behaviour Volume
mute = const 0.0

envelope :: Envelope -> Duration -> Time -> Behaviour Volume
envelope Envelope{..} sustainDuration start t
  | t < start = mute
  | t < afterAttack = t / _attackDuration -- vai de 0 para 1
  | t < afterDecay = let t' = t - afterAttack
                      in lerp (t' / _decayDuration) 1.0 _sustainLevel
  | t < afterSustain = const _sustainLevel
  | t < afterRelease = let t' = t - afterSustain
                        in lerp (t' / _releaseDuration) _sustainLevel 0.0
  | otherwise = mute
    where afterAttack = start + _attackDuration
          afterDecay = afterAttack + _decayDuration
          afterSustain = afterDecay + sustainDuration
          afterRelease = afterSustain + _releaseDuration
```

Aqui podemos notar algumas coisas. Primeiramente, essa implementação não é muito elegante, tem bastante código duplicado que poderíamos abstrair, mas por agora basta vai funcionar. Além disso, vale notar que `sustainDuration` não é parte do tipo `Envelope`, mas sim um parâmetro separado. Isso porque ele representa o tempo que o usuário segura a tecla do piano, por ex, ou seja, não faz parte da configuração de um envelope mas é um input do usuário. Por agora, vamos deixar tudo hardcoded mesmo, depois revisitaremos isso. Outra coisa que poderíamos customizar é a forma que toma as curvas de _attack_, _decay_ e _release_.

Para testar o novo envelope, vamos fazer outra amostragem e escrever no arquivo!

```haskell
samples :: [Float]
samples = tone1Samples ++ tone2Samples -- Concatena
    where tone1Samples = fmap tone1 sampleTimes
          tone2Samples = fmap tone2 sampleTimes

          -- Mudar o volume de um som é tão simples quanto multiplicar
          -- por um Behaviour de volume!
          tone1 = noteEnvelope 0.0 * semitonesUp 0 -- Um Lá
          tone2 = noteEnvelope 1.0 * semitonesUp 2 -- Um Sí

          sampleTimes1 = [0.0, 1.0/sampleRate ..1.0]
          sampleTimes2 = [1.0, 1.0 + 1.0/sampleRate ..2.0]

          noteEnvelope = envelope envelopeConfig 0.8

          envelopeConfig = Envelope { _attackDuration = 0.1
                                    , _decayDuration = 0.05
                                    , _sustainLevel = 0.8
                                    , _releaseDuration = 0.1
                                    }
```

Uma outra coisa que podemos perceber é que, por conta dos envelopes, o volume do `tone1` vai ser `0` depois do primeiro segundo e o volume de `tone2` vai ser `0` no primeiro segundo. Ou seja, se adicionarmos as duas ondas, obteremos uma única onda que no primeiro segundo toca o Lá e no segundo toca o Sí.

```haskell
samples :: [Float]
samples = waveSamples
    where waveSamples = fmap wave sampleTimes
          wave = tone1 + tone2
          sampleTimes = [0.0, 1.0/sampleRate .. 2.0]

          -- Mudar o volume de um som é tão simples quanto multiplicar
          -- por um Behaviour de volume!
          tone1 = noteEnvelope 0.0 * semitonesUp 0 -- Um Lá
          tone2 = noteEnvelope 1.0 * semitonesUp 2 -- Um Sí

          noteEnvelope = envelope envelopeConfig 0.8

          envelopeConfig = Envelope { _attackDuration = 0.1
                                    , _decayDuration = 0.05
                                    , _sustainLevel = 0.8
                                    , _releaseDuration = 0.1
                                    }
```

Isso pode parecer besta, mas na realidade evita uma operação `++` que é custosa em haskel, já que a implementação de lista é uma lista encadeada simples, então o operador de concatenação `++` executa em $O(n)$.

Você já deve ter imaginado que se somarmos duas ondas de tons diferentes ao mesmo tempo, teremos um acorde! A única questão é que é preciso ter cuidado na hora de somar essas notas para não exceder o limite: a onda final ainda tem que ser composta de valores  $\in [-1, 1]$ .

## Escrevendo um arquivo .wav

Vamos fazer uma pequena pausa e um desvio para entender como podemos escrever esses sons num arquivo de áudio mais convencional que poderia ser reproduzido por um aplicativo de som qualquer. Um dos formatos de áudio é o formato `.wav` e ele possui suporte a alguns tipos de codificação, inclusive a codificação em floats de 32 bits little-endian o que facilita muito a nossa vida.

Todo arquivo `.wav` começa com um cabeçalho que contém algumas informações sobre o tipo do arquivo, tamanho do arquivo, etc. Depois seguem algumas seções que descrevem o _bitrate_, _sample rate_ e número de samples, etc. Nada muito relevante. De fato esse formato de arquivo é literalmente os dados brutos que estávamos gerando precedidos de um cabeçalho pequeno. O código que segue escreve os dados num arquivo.

```haskell
writeWAV :: FilePath -> [Float] -> IO ()
writeWAV path wave = do
    let bytes = Bytes.toStrict $ Bytes.toLazyByteString
                                    $ toBytesBuilder wave
    let datasize = Bytes.length bytes
    let fsize = 44 {- header size -} + fromIntegral datasize
    let numSamples = fromIntegral datasize `div` 4
    let header = Bytes.byteString "RIFF"
              <> Bytes.int32LE (fsize - 8)
              <> Bytes.byteString "WAVE"
              <> Bytes.byteString "fmt "
                 -- Size of the rest of the subchunk following this number
              <> Bytes.int32LE 16
                 -- Format flag: floating point
              <> Bytes.int16LE 3
                 -- Number of channels
              <> Bytes.int16LE 1
              <> Bytes.int32LE sampleRate
                 -- SampleRate * NumChannels * BitsPerSample/8
              <> Bytes.int32LE (sampleRate * bitsPerSample `div` 8)
                 -- NumChannels * BitsPerSample/8
              <> Bytes.int16LE (bitsPerSample `div` 8)
              <> Bytes.int16LE bitsPerSample
              <> Bytes.byteString "fact"
                 -- Size of the rest of the subchunk following this number
              <> Bytes.int32LE 4
                 -- Number of sample frames
              <> Bytes.int32LE numSamples
              <> Bytes.byteString "data"
                 -- NumSamples * NumChannels * BitsPerSample/8
              <> Bytes.int32LE (numSamples * bitsPerSample `div` 8)

    withFile path WriteMode $ \h -> do
        Bytes.hPutBuilder h header
        Bytes.hPut h bytes
```

Por fim, basta mudar a `main` para

```haskell
main = writeWAV "sound.wav" (toBytesBuilder samples)
```

e pronto! Já dá pra ouvir o som com qualquer programa tradicional de áudio.

## Reatividade

Até agora vimos somente formas muito estáticas de trabalhar com behaviours. Podemos combinar diferentes tipos de behaviours e criar novos, mas esse ainda não é um sistema poderoso o suficiente para receber dados de um usuário e produzir sons de acordo com ele. Para isso é necessário introduzir outro conceito: os eventos. Um evento, é análogo a uma lista de pares tempo-valor

```haskell
type Event a = [(Time, a)] -- Tempos ordenados em ordem crescente
```

É possível ter diversos eventos que ocorrem no mesmo momento ou ter um grande intervalo entre eventos. Os eventos são como ocorrências discretas no tempo. Elas não possuem "infinita resolução" assim como os _behaviours_. Eles são justamente o que permite a interação com o mundo externo, imagine um `Event KeyEvent` onde `KeyEvent` poderia notificar qual tecla foi pressionada ou solta pelo usuário.

Assim como podemos combinar _behaviours_, também há formas de combinar _events_, vamos olhar a algumas dessas formas

```haskell
-- Faz um _merge_ dos eventos, intercalando os que vem primeiro antes
-- das ocorrências posteriores
(.|.) :: Event a -> Event a -> Event a
[] .|. ys = ys
xs .|. [] = xs
((tx, x) : xs) .|. ((ty, y) : ys)
  | tx <= ty = (tx, x) : (xs .|. ((ty, y) : ys))
  | otherwise = (ty, y) : (((tx, x) : xs) .|. ys)

-- Grava o valor do behaviour no momento em que o evento ocorre
snapshot :: Behaviour b -> Event a -> Event (a, b)
snapshot _ [] = []
snapshot b ((te, e) : es) = (te, (e, b te)) : snapsnot b es

-- Esse é a função mais importante de todas, ela é quem realmente
-- permite a reatividade. Ela toma como argumento um behaviour
-- padrão e um evento (lista) de behaviours e retorna outro behaviour
-- que é atua como o behaviour do último evento ocorrido ou como o
-- padrão se não ouveram eventos antes desse momento.
switcher :: Behaviour a -> Event (Behaviour a) -> Behaviour a
switcher b events t = last (b : before) t
    where  -- Eventos que ocorrem antes de `t`
           before = [e | (te, e) <- events, te < t]
```

Com isso, já podemos definir melhor como mudar de notas, podemos ter um evento que representa quando queremos que cada nota seja tocada. Daí, usamos um `switcher` para trocar entre elas!

```haskell
notesToPlay = []
```

## To be continued...
