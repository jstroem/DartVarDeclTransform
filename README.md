DartVarDeclTransform
================

Simple Command line tool to transform variable declarations list into variable declaration list which only constists of one.
This is not possible when variable declarations is used inside a for statement. 

## Introduction

This tool is written by Jesper Lindstrøm Nielsen and Troels Leth Jensen as part of a study in Dart at Aarhus University @ 2014.

## Install

When cloned you should get the packages needed to use via. `pub get`.

## Run

To use the tool just do:

  ./vardecl_transform.dart [-w --override] file(s)

The tool implement these flags:

Override `-w` or `--override` flag to specify of the given file should be overwritten whit the transformed result.