5 CLS
10 PRINT "Welcome to my guessing game."
20 PRINT "I will think of a number from 1 to 100"
30 PRINT "and you must guess it.  I will tell you"
40 PRINT "if you are high or low."
50 PRINT
60 g = INT(RND(0)*100)
100 INPUT "your guess"; u
110 IF u < g THEN GOTO 200
120 IF u > g THEN GOTO 300
130 PRINT "You got it!"
140 END
200 PRINT "LOW"
210 GOTO 100
300 PRINT "HIGH"
310 GOTO 100