library parser_perf;

import '_perf.dart';
import 'dart:async';
import 'package:angular/scope.dart';
import 'package:angular/parser/parser_library.dart';
import 'package:di/di.dart';
import 'package:di/dynamic_injector.dart';
import 'package:intl/intl.dart';

import '../gen/generated_functions.dart' as generated_functions;
import '../gen/generated_getter_setter.dart' as generated_getter_setter;

main() {
  var injector = new DynamicInjector(
      modules: [new Module()
        ..type(Parser, implementedBy: DynamicParser)],
      allowImplicitInjection:true);
  var scope = injector.get(Scope);
  var reflectiveParser = injector.get(Parser);
  var generatedParser = new DynamicInjector(
      modules: [new Module()
        ..type(Parser, implementedBy: StaticParser)
        ..value(StaticParserFunctions, generated_functions.functions())],
      allowImplicitInjection:true).get(Parser);
  var hybridParser = new DynamicInjector(
      modules: [new Module()
        ..type(Parser, implementedBy: DynamicParser)
        ..type(GetterSetter, implementedBy: generated_getter_setter.StaticGetterSetter)],
      allowImplicitInjection:true).get(Parser);

  scope['a'] = new ATest();
  scope['e1'] = new EqualsThrows();

  compare(expr, idealFn) {
    var nf = new NumberFormat.decimalPattern();
    var reflectionExpr = reflectiveParser(expr);
    var generatedExpr = generatedParser(expr);
    var hybridExpr = hybridParser(expr);
    var measure = (b) => statMeasure(b).mean_ops_sec;
    var gTime = measure(() => generatedExpr.eval(scope));
    var rTime = measure(() => reflectionExpr.eval(scope));
    var hTime = measure(() => hybridExpr.eval(scope));
    var iTime = measure(() => idealFn(scope));
    print('$expr => g: ${nf.format(gTime)} ops/sec   ' +
          'r: ${nf.format(rTime)} ops/sec   ' +
          'h: ${nf.format(hTime)} ops/sec   ' +
          'i: ${nf.format(iTime)} ops/sec = ' +
          'i/g: ${nf.format(iTime / gTime)} x  ' +
          'i/r: ${nf.format(iTime / rTime)} x  ' +
          'i/h: ${nf.format(iTime / hTime)} x  ' +
          'g/h: ${nf.format(gTime / hTime)} x  ' +
          'h/r: ${nf.format(hTime / rTime)} x  ' +
          'g/r: ${nf.format(gTime / rTime)} x');
  }

  compare('a.b.c', (scope) => scope['a'].b.c);
  compare('e1.b', (scope) => scope['e1'].b);
  compare('null', (scope) => null);
  compare('x.b.c', (s, [l]) {
    if (l != null && l.containsKey('x')) s = l['x'];
    else if (s != null ) s = s is Map ? s['x'] : s.x;
    if (s != null ) s = s is Map ? s['b'] : s.b;
    if (s != null ) s = s is Map ? s['c'] : s.c;
    return s;
  });
  compare('doesNotExist', (scope) => scope['doesNotExists']);
}


class ATest {
  var b = new BTest();
}

class BTest {
  var c = 6;
}

class EqualsThrows {
  var b = 3;
  operator ==(x) {
    try {
      throw "no";
    } catch (e) {
      return false;
    }
  }
}

