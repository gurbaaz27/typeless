# CS350A Course Project
## λ-calculus interpreter

### Table of Contents

- [Description](#description)
- [Usage](#usage)
- [Team Members](#team-members)

## Description

An interpreter for λ-calculus implemented in `ruby`, as part of our course project CS350A: Principles of Programming Languages under Prof. Satyadev Nandakumar, in Fall Semester 2022-23, IIT Kanpur.

The grammar specification is:
```
λ − term ::= variable |
            (\variable · λ − term) |
            [λ − term][λ − term]

The allowed variables are single lowercase English letters - a, b, c etc.
```

It supports the following features:
- [x] Lexer and grammar checker for lambda term expression using LL(1) parser
- [x] Determine free variables in given lambda term
- [x] Free variables substitution
- [x] Alpha Renaming and Beta Reduction

### Code Structure

```bash
.
├── assets/
├── lexer.rb
├── LICENSE
├── main.rb
├── parser.rb
├── README.md
├── reducer.rb
├── tests/
└── utils.rb

2 directories, 14 files
```

## Usage

Keep your λ-expression in a file and pass its filepath as an argument to `main.rb`.

```bash
Lambda Calculus Interpreter
===========================
Usage: main.rb [options]
    -i, --input FILE                 Input file containing λ-expression
    -o, --output FILE                (Optional) Output file to store reduced λ-expression. Default: out.txt
```

### Demo Example

```bash
$ ruby main.rb -i tests/8.lc ## or
$ ruby main.rb --input=tests/8.lc

[ ( \ x . ( \ x . x ) ) ] [ ( \ x . x ) ] is a valid lambda term
Free variables :- none
α-renaming :- [ ( \ v0 . ( \ v1 . v1 ) ) ] [ ( \ v2 . v2 ) ]
β-reduction :- 
Step 1. ( \ v1 . v1 )
No further reduction possible!
Final β-reduced form saved to out.txt:- 
( \ v1 . v1 )
```

You may find some of the lambda expression files in `tests/` directory.

## Team Members

1. Ayush Kumar (190213)
2. Gurbaaz Singh Nandra (190349)
3. Kritin Sharma (190440)