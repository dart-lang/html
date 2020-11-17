/// Query selector implementation for our DOM.
library html.src.query;

import 'package:csslib/parser.dart' as css;
import 'package:csslib/parser.dart' show TokenKind, Message;
import 'package:csslib/visitor.dart'; // the CSSOM
import 'package:html/dom.dart';
import 'package:html/src/constants.dart' show isWhitespaceCC;

bool matches(Element node, String selector) =>
    SelectorEvaluator().matches(node, _parseSelectorList(selector));

Element querySelector(Node node, String selector) =>
    SelectorEvaluator().querySelector(node, _parseSelectorList(selector));

List<Element> querySelectorAll(Node node, String selector) {
  final results = <Element>[];
  SelectorEvaluator()
      .querySelectorAll(node, _parseSelectorList(selector), results);
  return results;
}

// http://dev.w3.org/csswg/selectors-4/#grouping
SelectorGroup _parseSelectorList(String selector) {
  final errors = <Message>[];
  final group = css.parseSelectorGroup(selector, errors: errors);
  if (group == null || errors.isNotEmpty) {
    throw FormatException("'$selector' is not a valid selector: $errors");
  }
  return group;
}

class SelectorEvaluator extends Visitor {
  /// The current HTML element to match against.
  Element _element;

  bool matches(Element element, SelectorGroup selector) {
    _element = element;
    return visitSelectorGroup(selector);
  }

  Element querySelector(Node root, SelectorGroup selector) {
    for (var element in root.nodes.whereType<Element>()) {
      if (matches(element, selector)) return element;
      final result = querySelector(element, selector);
      if (result != null) return result;
    }
    return null;
  }

  void querySelectorAll(
      Node root, SelectorGroup selector, List<Element> results) {
    for (var element in root.nodes.whereType<Element>()) {
      if (matches(element, selector)) results.add(element);
      querySelectorAll(element, selector, results);
    }
  }

  @override
  bool visitSelectorGroup(SelectorGroup group) =>
      group.selectors.any(visitSelector);

  @override
  bool visitSelector(Selector selector) {
    final old = _element;
    var result = true;

    // Note: evaluate selectors right-to-left as it's more efficient.
    int combinator;
    for (var s in selector.simpleSelectorSequences.reversed) {
      if (combinator == null) {
        result = s.simpleSelector.visit(this) as bool;
      } else if (combinator == TokenKind.COMBINATOR_DESCENDANT) {
        // descendant combinator
        // http://dev.w3.org/csswg/selectors-4/#descendant-combinators
        do {
          _element = _element.parent;
        } while (_element != null && !(s.simpleSelector.visit(this) as bool));

        if (_element == null) result = false;
      } else if (combinator == TokenKind.COMBINATOR_TILDE) {
        // Following-sibling combinator
        // http://dev.w3.org/csswg/selectors-4/#general-sibling-combinators
        do {
          _element = _element.previousElementSibling;
        } while (_element != null && !(s.simpleSelector.visit(this) as bool));

        if (_element == null) result = false;
      }

      if (!result) break;

      switch (s.combinator) {
        case TokenKind.COMBINATOR_PLUS:
          // Next-sibling combinator
          // http://dev.w3.org/csswg/selectors-4/#adjacent-sibling-combinators
          _element = _element.previousElementSibling;
          break;
        case TokenKind.COMBINATOR_GREATER:
          // Child combinator
          // http://dev.w3.org/csswg/selectors-4/#child-combinators
          _element = _element.parent;
          break;
        case TokenKind.COMBINATOR_DESCENDANT:
        case TokenKind.COMBINATOR_TILDE:
          // We need to iterate through all siblings or parents.
          // For now, just remember what the combinator was.
          combinator = s.combinator;
          break;
        case TokenKind.COMBINATOR_NONE:
          combinator = null;
          break;
        default:
          throw _unsupported(selector);
      }

      if (_element == null) {
        result = false;
        break;
      }
    }

    _element = old;
    return result;
  }

  UnimplementedError _unimplemented(SimpleSelector selector) =>
      UnimplementedError("'$selector' selector of type "
          '${selector.runtimeType} is not implemented');

  FormatException _unsupported(selector) =>
      FormatException("'$selector' is not a valid selector");

  @override
  bool visitPseudoClassSelector(PseudoClassSelector selector) {
    switch (selector.name) {
      // http://dev.w3.org/csswg/selectors-4/#structural-pseudos

      // http://dev.w3.org/csswg/selectors-4/#the-root-pseudo
      case 'root':
        // TODO(jmesserly): fix when we have a .ownerDocument pointer
        // return _element == _element.ownerDocument.rootElement;
        return _element.localName == 'html' &&
            (_element.parentNode == null || _element.parentNode is Document);

      // http://dev.w3.org/csswg/selectors-4/#the-empty-pseudo
      case 'empty':
        return _element.nodes
            .every((n) => !(n is Element || n is Text && n.text.isNotEmpty));

      // http://dev.w3.org/csswg/selectors-4/#the-blank-pseudo
      case 'blank':
        return _element.nodes.any((n) => !(n is Element ||
            n is Text && n.text.runes.any((r) => !isWhitespaceCC(r))));

      // http://dev.w3.org/csswg/selectors-4/#the-first-child-pseudo
      case 'first-child':
        return _element.previousElementSibling == null;

      // http://dev.w3.org/csswg/selectors-4/#the-last-child-pseudo
      case 'last-child':
        return _element.nextElementSibling == null;

      //http://drafts.csswg.org/selectors-4/#first-of-type-pseudo
      //http://drafts.csswg.org/selectors-4/#last-of-type-pseudo
      //http://drafts.csswg.org/selectors-4/#only-of-type-pseudo
      case 'first-of-type':
      case 'last-of-type':
      case 'only-of-type':
        var parent = _element.parentNode;
        if (parent != null) {
          var children = parent.children.where((Element el) {
            return el.localName == _element.localName;
          }).toList();

          var index = children.indexOf(_element);
          var isFirst = index == 0;
          var isLast = index == children.length - 1;

          if (isFirst && selector.name == 'first-of-type') {
            return true;
          }

          if (isLast && selector.name == 'last-of-type') {
            return true;
          }

          if (isFirst && isLast && selector.name == 'only-of-type') {
            return true;
          }

          return false;
        }

        break;

      // http://dev.w3.org/csswg/selectors-4/#the-only-child-pseudo
      case 'only-child':
        return _element.previousElementSibling == null &&
            _element.nextElementSibling == null;

      // http://dev.w3.org/csswg/selectors-4/#link
      case 'link':
        return _element.attributes['href'] != null;

      //https://drafts.csswg.org/selectors-4/#checked-pseudo
      //https://drafts.csswg.org/selectors-4/#enabled-pseudo
      //https://drafts.csswg.org/selectors-4/#disabled-pseudo
      case 'enabled':
      case 'disabled':
        var isDisabled = selector.name == 'disabled';
        var interactableTypes = [
          'button',
          'input',
          'select',
          'textarea',
          'optgroup',
          'option',
          'fieldset'
        ];
        if (interactableTypes.contains(_element.localName)) {
          var disabled = _element.attributes['disabled'];

          if (disabled != null) {
            return isDisabled;
          }
        }

        return !isDisabled;

      //https://drafts.csswg.org/selectors-4/#checked-pseudo
      case 'checked':
        var isCheckable = _element.localName == 'option' ||
            (_element.localName == 'input' &&
                (_element.attributes['type'] == 'checkbox' ||
                    _element.attributes['type'] == 'radio'));

        if (isCheckable) {
          return _element.attributes['checked'] != null;
        }
        return false;

      case 'visited':
      case 'target':
        // Always return false since we aren't a browser. This is allowed per:
        // http://dev.w3.org/csswg/selectors-4/#visited-pseudo
        // http://drafts.csswg.org/selectors-4/#target-pseudo
        return false;
    }

    // :before, :after, :first-letter/line can't match DOM elements.
    if (_isLegacyPsuedoClass(selector.name)) return false;

    throw _unimplemented(selector);
  }

  @override
  bool visitPseudoElementSelector(PseudoElementSelector selector) {
    // :before, :after, :first-letter/line can't match DOM elements.
    if (_isLegacyPsuedoClass(selector.name)) return false;

    throw _unimplemented(selector);
  }

  static bool _isLegacyPsuedoClass(String name) {
    switch (name) {
      case 'before':
      case 'after':
      case 'first-line':
      case 'first-letter':
        return true;
      default:
        return false;
    }
  }

  @override
  bool visitPseudoElementFunctionSelector(PseudoElementFunctionSelector s) =>
      throw _unimplemented(s);

  num _countExpressionList(List<Expression> list) {
    Expression first = list[0];
    num sum = 0;
    num modulus = 1;
    if (first is OperatorMinus) {
      modulus = -1;
      list = list.sublist(1);
    }
    list.forEach((Expression item) {
      sum += (item as NumberTerm).value;
    });
    return sum * modulus;
  }

  Map<String, num> _parseNthExpressions(List<Expression> exprs) {
    num A;
    num B = 0;

    if (exprs.isNotEmpty) {
      if (exprs.length == 1 && (exprs[0] is LiteralTerm)) {
        LiteralTerm literal = exprs[0];
        if (literal is NumberTerm) {
          B = literal.value;
        } else {
          String value = literal.value.toString();
          if (value == 'even') {
            A = 2;
            B = 1;
          } else if (value == 'odd') {
            A = 2;
            B = 0;
          } else if (value == 'n') {
            A = 1;
            B = 0;
          } else {
            return null;
          }
        }
      }

      List<Expression> bTerms = [];
      List<Expression> aTerms = [];
      var nIndex = exprs.indexWhere((expr) {
        return (expr is LiteralTerm) && expr.value.toString() == 'n';
      });

      if (nIndex > -1) {
        bTerms.addAll(exprs.sublist(nIndex + 1));
        aTerms.addAll(exprs.sublist(0, nIndex));
      } else {
        bTerms.addAll(exprs);
      }

      if (bTerms.isNotEmpty) {
        B = _countExpressionList(bTerms);
      }

      if (aTerms.isNotEmpty) {
        if (aTerms.length == 1 && aTerms[0] is OperatorMinus) {
          A = -1;
        } else {
          A = _countExpressionList(aTerms);
        }
      } else {
        if (nIndex == 0) {
          A = 1;
        }
      }
    }

    return {'A': A, 'B': B};
  }

  @override
  bool visitPseudoClassFunctionSelector(PseudoClassFunctionSelector selector) {
    switch (selector.name) {
      // http://dev.w3.org/csswg/selectors-4/#child-index
      // http://dev.w3.org/csswg/selectors-4/#the-nth-child-pseudo

      case 'nth-child':
      case 'nth-last-child':
      case 'nth-of-type':
      case 'nth-last-of-type':
        //  i = An + B
        var nthData = _parseNthExpressions(selector.expression.expressions);
        if (nthData == null) {
          break;
        }

        var A = nthData['A'];
        var B = nthData['B'];

        var parent = _element.parentNode;

        if (parent != null) {
          var elIndex;
          var children = parent.children;

          if (selector.name == 'nth-of-type' ||
              selector.name == 'nth-last-of-type') {
            children = children.where((Element el) {
              return el.localName == _element.localName;
            }).toList();
          }

          if (selector.name == 'nth-last-child' ||
              selector.name == 'nth-last-of-type') {
            elIndex = children.length - children.indexOf(_element);
          } else {
            elIndex = children.indexOf(_element) + 1;
          }

          if (A == null) {
            return B > 0 && elIndex == B;
          } else {
            var divideResult = (elIndex - B) / A;

            if (divideResult >= 1) {
              return divideResult % divideResult.ceil() == 0;
            } else {
              return divideResult == 0;
            }
          }
        } else {
          return false;
        }

        break;

      // http://dev.w3.org/csswg/selectors-4/#the-lang-pseudo
      case 'lang':
        // TODO(jmesserly): shouldn't need to get the raw text here, but csslib
        // gets confused by the "-" in the expression, such as in "es-AR".
        final toMatch = selector.expression.span.text;
        final lang = _getInheritedLanguage(_element);
        // TODO(jmesserly): implement wildcards in level 4
        return lang != null && lang.startsWith(toMatch);
    }
    throw _unimplemented(selector);
  }

  static String _getInheritedLanguage(Node node) {
    while (node != null) {
      final lang = node.attributes['lang'];
      if (lang != null) return lang;
      node = node.parent;
    }
    return null;
  }

  @override
  bool visitNamespaceSelector(NamespaceSelector selector) {
    // Match element tag name
    if (!(selector.nameAsSimpleSelector.visit(this) as bool)) return false;

    if (selector.isNamespaceWildcard) return true;

    if (selector.namespace == '') return _element.namespaceUri == null;

    throw _unimplemented(selector);
  }

  @override
  bool visitElementSelector(ElementSelector selector) =>
      selector.isWildcard || _element.localName == selector.name.toLowerCase();

  @override
  bool visitIdSelector(IdSelector selector) => _element.id == selector.name;

  @override
  bool visitClassSelector(ClassSelector selector) =>
      _element.classes.contains(selector.name);

  // TODO(jmesserly): negation should support any selectors in level 4,
  // not just simple selectors.
  // http://dev.w3.org/csswg/selectors-4/#negation
  @override
  bool visitNegationSelector(NegationSelector selector) =>
      !(selector.negationArg.visit(this) as bool);

  @override
  bool visitAttributeSelector(AttributeSelector selector) {
    // Match name first
    final value = _element.attributes[selector.name.toLowerCase()];
    if (value == null) return false;

    if (selector.operatorKind == TokenKind.NO_MATCH) return true;

    final select = '${selector.value}';
    switch (selector.operatorKind) {
      case TokenKind.EQUALS:
        return value == select;
      case TokenKind.INCLUDES:
        return value.split(' ').any((v) => v.isNotEmpty && v == select);
      case TokenKind.DASH_MATCH:
        return value.startsWith(select) &&
            (value.length == select.length || value[select.length] == '-');
      case TokenKind.PREFIX_MATCH:
        return value.startsWith(select);
      case TokenKind.SUFFIX_MATCH:
        return value.endsWith(select);
      case TokenKind.SUBSTRING_MATCH:
        return value.contains(select);
      default:
        throw _unsupported(selector);
    }
  }
}
