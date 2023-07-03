# Installation
To use this calculator program, follow these steps:

Ensure that you have a C compiler installed on your system. If not, install a C compiler compatible with your operating system.

Install Flex and Bison on your system. Flex is a lexical analyzer generator, and Bison is a parser generator. They are used to generate the lexer and parser for the calculator program.

For Linux-based systems, you can install Flex and Bison using the package manager of your distribution. For example, on Ubuntu, you can run the following command:

```
sudo apt-get install flex bison
```


For macOS, you can install Flex and Bison using Homebrew. Run the following commands:
```
brew install flex
brew install bison
```



# Build and Run
Clone this repository to your local machine or download the source code as a ZIP file.

Open a terminal or command prompt and navigate to the project directory.
To build and run the calculator program, follow these steps:

Make sure you are in the project directory using the terminal or command prompt.

Run the following command to build the calculator program:

```
make
```

This command will compile the Flex and Bison source files, generate the lexer and parser code, and link them to create the mycalc executable and run it.

Once the build process is complete, you can run the calculator program using the following command:

```
./mycalc input
```
Replace input with the name of the input file containing the arithmetic expressions you want to evaluate. The input file should follow the syntax rules specified in the program.

After running the calculator program, it will display the results of the arithmetic expressions in the input file.

# Cleaning Up
To clean up the project directory and remove the generated files, run the following command:
```
make clean
```
This command will remove the generated lexer and parser files, the mycalc executable, and any intermediate files.