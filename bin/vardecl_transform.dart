#!/usr/bin/env dart

import 'dart:io';
import 'dart:math';
import 'package:analyzer/src/services/formatter_impl.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:args/args.dart';

main(List<String> args) {
  ArgParser argParser = new ArgParser();
  argParser..addFlag('override', help: "If set, overrides the files with the stripped version", abbr: 'w', defaultsTo: false, negatable: false);
  ArgResults results = argParser.parse(args);

  List<String> files = results.rest;
  
  for (String arg in files) {
    CodeFormatterImpl cf = new VarDeclFormatterImpl(const FormatterOptions());
    CodeFormatter finisher = new CodeFormatter();
    File file = new File(arg);
    var src = file.readAsStringSync();
    FormattedSource fs = cf.format(CodeKind.COMPILATION_UNIT, src);
    try {
    fs = finisher.format(CodeKind.COMPILATION_UNIT, fs.source);
    } catch (e){
      print("error during formatting: ${e}");
      print(fs.source);
      exit(15);
    }
    
    if (results['override'])
      file.writeAsStringSync(fs.source);
    else
      print(fs.source);
  }
}

class VarDeclFormatterImpl extends CodeFormatterImpl {
  
  VarDeclFormatterImpl(options):super(options);
  
  
  FormattedSource format(CodeKind kind, String source, {int offset, int end,
      int indentationLevel: 0, Selection selection: null}) {

    var startToken = tokenize(source);
    checkForErrors();

    var node = parse(kind, startToken);
    checkForErrors();

    var t = node.toString();
    
    var formatter = new VarDeclFormatSourceVisitor(options, lineInfo, source, selection);
    node.accept(formatter);
    formatter = new VarDeclFormatSourceVisitor(options, lineInfo, source, selection);
    node.accept(formatter);

    var formattedSource = formatter.writer.toString();

    return new FormattedSource(formattedSource, formatter.selection);
  }
}

class VarDeclFormatSourceVisitor extends SourceVisitor {
  VarDeclFormatSourceVisitor(options, lineInfo, source, preSelection): super(options, lineInfo, source, preSelection);
  
  List<String> typeArguments = new List<String>();
  
  void detach(AstNode parent, AstNode child){
    child.parent = null;
  }
  
  Token copyToken(Token t){
    return new Token(t.type, t.offset);
  }
  /*
  TypeName copyTypeName(TypeName t){
    t.
  }*/
    
  
  visitVariableDeclarationList(VariableDeclarationList node) {
    
    if (node.variables.length > 1){
      List<VariableDeclaration> varsToTransform = <VariableDeclaration>[];  
      
      for(var i = 1; i < node.variables.length; i++){
        detach(node, node.variables[i]);
        varsToTransform.add(node.variables[i]);
      }
      
      if (node.parent is FieldDeclaration && node.parent.parent is ClassDeclaration){
        FieldDeclaration fieldDecl = node.parent;
        ClassDeclaration classDecl = fieldDecl.parent;
        VariableDeclaration v = node.variables[0];
        node.variables.clear();
        node.variables.add(v);
        super.visitVariableDeclarationList(node);
        ClassMember lastFieldDecl = fieldDecl;
        var i = 1;
        for(v in varsToTransform){
          VariableDeclarationList varDeclList = new VariableDeclarationList(node.documentationComment, node.metadata, node.keyword, node.type, [v]);
          FieldDeclaration fieldDeclCopy = new FieldDeclaration(fieldDecl.documentationComment, fieldDecl.metadata, fieldDecl.staticKeyword, varDeclList, fieldDecl.semicolon);
          classDecl.members.insert(classDecl.members.indexOf(lastFieldDecl) + i++, fieldDeclCopy);
          //this.visitFieldDeclaration(fieldDeclCopy);
        }
        
      } else if (node.parent is VariableDeclarationStatement && node.parent.parent is Block) {
        VariableDeclarationStatement varDeclStatement = node.parent;
        Block block = varDeclStatement.parent;
        
        VariableDeclaration v = node.variables[0];
        node.variables.clear();
        node.variables.add(v);
        super.visitVariableDeclarationList(node);
        
        for(v in varsToTransform){
          VariableDeclarationList varDeclList = new VariableDeclarationList(node.documentationComment, node.metadata, node.keyword, node.type, [v]);
          VariableDeclarationStatement varDeclStmtCopy = new VariableDeclarationStatement(varDeclList, varDeclStatement.semicolon);
          block.statements.insert(block.statements.indexOf(varDeclStatement) + 1, varDeclStmtCopy);
          //this.visitVariableDeclarationStatement(varDeclStmtCopy);
        }
      } else if (node.parent is TopLevelVariableDeclaration && node.parent.parent is CompilationUnit){
        TopLevelVariableDeclaration varDecl = node.parent;
        CompilationUnit unit = varDecl.parent;
        
        VariableDeclaration v = node.variables[0];
        node.variables.clear();
        node.variables.add(v);
        super.visitVariableDeclarationList(node);
        
        for(v in varsToTransform){
          VariableDeclarationList varDeclList = new VariableDeclarationList(node.documentationComment, node.metadata, node.keyword, node.type, [v]);
          TopLevelVariableDeclaration varDeclCopy = new TopLevelVariableDeclaration(varDecl.documentationComment, varDecl.metadata, varDeclList, varDecl.semicolon);
          unit.declarations.insert(unit.declarations.indexOf(varDecl) + 1, varDeclCopy);
          //this.visitTopLevelVariableDeclaration(varDeclCopy);
        }
        
      } else {
        print("Not transformed: ${node.parent.runtimeType} - ${node.parent.parent.runtimeType}");
        super.visitVariableDeclarationList(node);
      }
      
    /*
      for(VariableDeclaration v in varsToTransform){
        VariableDeclarationList declList = new VariableDeclarationList(null, node.metadata, node.keyword, node.type, [v]);
        declList.parent = node.parent;
        if (node.parent is Block){
          Block block = node.parent;
        } else {
          print("IS NOT A BLOCK WHATTT!!! ${node.parent.runtimeType}");
          exit(15);
        }
      }*/
      
      //new VariableDeclarationList(comment, metadata, keyword, type, variables)
      
    } else {
      super.visitVariableDeclarationList(node);
    }
  }
}

