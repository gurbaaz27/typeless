# CS350A Course Project

### Table of Contents

- [Description](#description)
- [Usage](#usage)
- [Team Members](#team-members)

## Description

Implementation language: `ruby`

Supports the following features:
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

Keep your lambda expression in a file and pass its filepath as argument to `compiler.rb`.

```bash
ruby main.rb <lambda-expression-input-file-path>
```

You may find some of the lambda expression files in `tests/` directory.

## Team Members

1. Ayush Kumar (190213)
2. Gurbaaz Singh Nandra (190349)
3. Kritin Sharma (190440)