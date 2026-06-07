loadi $sp, 200
loadi $t0, 10
loadi $t1, 20
addi3 $t2, $t0, $t1, 5
swap  $t0, $t1
mul   $t3, $t0, $t1
push  $t3
pop   $t4
bgt   $t0, $t1, target
loadi $t5, 99
target:
loadi $t6, 100
