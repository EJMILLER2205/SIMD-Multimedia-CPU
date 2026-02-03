#Forwarding Test for R3 Instructions

LI r2, 5, 0			#r2 = 5
AHS r10, r2, r2		#r10 = 10
MLHU r16, r2, r2	#r16 = 25
AND r24, r16, r2	#r24 = 1
OR r30, r10, r24	#r30 = 11
SFWU r12, r10, r16	#r12 = 5
