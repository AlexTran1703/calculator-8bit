# Calculator-8bit
- The calculator compute 8 bit basic operation +, -, x, / and display result on LCD. The keyboard input takes operation from user to compute the calculation.
- The project is designed based on C language and Assembly.
- The project is simulated on Proteus and the compiled code use AVR Studio 4.
- The software composes of 2 input numbers __a__ and __b__. When ever an operandis pressed, the number __a__ will  be stored and number __b__ will wait for the input from user. When the user press __=__, the calculator compute __a__ and __b__.
![Software Desgin Flow](/results/flow_chart.jpg)
## Components
![Project components](/results/calculator_atmega32.jpg)
- Hardware: ATMega32, Keyboard 4x4, LCD 16x2

- Software: C, Assembly

- Tools: Proteus, AVR Studio 4
## Assembly
![AVR Assembly](/results/calculator_assembly.jpg)
- The __Assembly Calculator__ can only compute 8 bit operation. 
## C Language
![AVR C](/results/calculator_programmingC.jpg)
- The __C Calculator__ can compute operation larger than 8 bit.
