<div style="display: flex; justify-content: center;">
  <img src="EMP100L.svg" alt="Logo" width="300">
</div>

# EMP-Arch
##### Embedded. Markarian. Processors. Architecture

Los EMP son procesadores de 8 bits portatiles y simples
Con un balance entre rendimiento y abstraccion.

Cuenta con mas de 19 instrucciones, incluye acceso extendido
a memoria con paginas de 256 bytes cada una, dando 
64KB usables que pueden mapearse de manera muy customizada

Debido a que la memoria, las instrucciones y los branches
pasan primero por los pines para poder lograrlo.

Los procesadores no cuentan Program Counter ni memoria propia
debido a que solo contiene pines I/O de la memoria y demas
pines para poder mandarle instrucciones que es la unica forma
de ejecutar algo util.

Su diseño esta basado en una combinacion de base CISC y RISC
aunque intenta ser lo mas ligero posible pero sin tener que
hacer trucos de registros y intercambios

En las revisiones listadas a continuacion son los modelos
de set de instrucciones

* **EMP-100**: el modelo base del set de instrucciones, incluye operaciones de memoria basicas, operaciones de bit a bit, operaciones simples como suma y resta, entre otros
* **EMP-1000**: se basa en los modelos anteriores contando que este mismo incluye instrucciones para tareas pesadas y hacerlas mas rapido, como la capacidad de indexear memoria y cargarla o escribirla con en o desde el acumulador usando un registro y luego incrementar o decrementarlo en la misma instruccion dependiendo de el bit 6 de las banderas (DF)