<div style="display: flex; justify-content: center;">
  <img src="EMP100L.svg" alt="Logo" width="300">
</div>

# EMP-Arh
##### Embedded. Markarian. Processors. Architecture

Los EMP son procesadores de 8 bits portatiles y simples
Con un balance entre rendimiento y abstraccion.

Cuenta con mas de 19 instrucciones, incluye acceso extendido
a memoria con paginas de 256 bytes cada una, dando 
64KB usables que pueden mapearse de manera muy customizada

Debido a que la memoria, las instrucciones y los branches
pasan primero por los pines para poder lograrlo.

El procesador no tiene Program Counter ni memoria incluida
debido a que solo contiene pines I/O de la memoria y otros
pines para poder mandarle instrucciones que es la unica forma
de ejecutar algo util.

Su diseño esta basado en una combinacion de base CISC y RISC
aunque intenta ser lo mas ligero posible pero sin tener que
hacer trucos de registros y mas cosas