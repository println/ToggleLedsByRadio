#Sistemas de tempo real e embarcado

###Aplicativo que use 3 nós.

1. O primeiro nó acende o LED vermelho e manda o segundo nó acender o mesmo.
1. O segundo, ao acender seu LED, manda o terceiro nó acender o mesmo.
1. O terceiro nó, ao acender seu LED vermelho, envia a mensagem para o primeiro nó, o qual vai acender o LED verde e repassar.
1. Quando os três LEDs estiverem acessos, o primeiro nó irá enviar o comando de desligar todos.
1. O aplicativo roda indefinidamente.  

