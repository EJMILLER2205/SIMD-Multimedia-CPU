#Forwarding test for R4 Instruction

LI r2, 5, 0				#r2 = 5
MADDL r11, r2, r2, r2	#r11 = 30
MADDL r23, r2, r2, r2	#r23 = 30
MADDL r31, r23, r23, r2 #r31 = 180
MADDL r17, r11, r11, r2 #r17 = 180
LI r1, 3, 0				#r1 = 3
MSUBL r8, r17, r1, r1   #r8 = 171
MSUBL r6, r23, r1, r1	#r6 = 21
MADDL r19, r6, r1, r6	#r19 = 84
MADDL r26, r23, r1, r23 #r26 = 120
MSUBL r9, r26, r1, r2	#r9 = 105
MADDL r20, r17, r9, r1	#r20 = 495
LI r4, 8, 0				#r4 = 8
MSUBL r7, r20, r6, r4	#r7 = 327
MSUBL r14, r20, r2, r19 #r14 = 75
MADDL r28, r4, r14, r4  #r28 = 608
LI r5, 4, 0				#r5 = 4
MADDL r13, r19, r19, r5 #r13 = 420
MUSBL r25, r13, r4, r4	#r25 = 356
