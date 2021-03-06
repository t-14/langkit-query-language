"""
The aim of this directive is to document inline which classes of the LKQL
hierarchy are already documented, in reference_manual.rst, and get a report of
which classes remain to be documented.
"""


from collections import defaultdict
from docutils import nodes
from functools import lru_cache

from sphinx.util.docutils import SphinxDirective
from sphinx.errors import ExtensionError

import liblkqllang
import traceback

lkql_classes = [
    v for _, v in liblkqllang.__dict__.items()
    if (type(v) == type
        and issubclass(v, liblkqllang.LKQLNode))
]


@lru_cache
def lkql_cls_subclasses():
    """
    Return a dict of class to direct subclasses.
    """
    res = defaultdict(list)
    for cls in lkql_classes:
        if cls != liblkqllang.LKQLNode:
            res[cls.__base__].append(cls)
    return res


@lru_cache(maxsize=None)
def is_class_documented(lkql_class):
    """
    Helper function: whether a class is documented, taking inheritance into
    account (if all subclasses of a class are documented, then the class is
    documented).
    """
    subclasses = lkql_cls_subclasses()[lkql_class]
    return (
        getattr(lkql_class, "documented", False)
        or (len(subclasses) > 0
            and all(is_class_documented(subcls)
                    for subcls in lkql_cls_subclasses()[lkql_class]))
    )


class LKQLDocClassDirective(SphinxDirective):
    """
    Directive to be used to annotate documentation of an LKQL node.
    """

    has_content = False
    required_arguments = 1
    optional_arguments = 0

    def run(self):
        targetid = 'lkqldocclass-%d' % self.env.new_serialno('lkqldocclass')
        targetnode = nodes.target('', '', ids=[targetid])

        cls_name = self.arguments[0]

        if not hasattr(self.env, 'documented_classes'):
            self.env.documented_classes = []

        try:
            lkql_class = getattr(liblkqllang, cls_name)
            self.env.documented_classes.append(lkql_class)
            lkql_class.documented = True
        except AttributeError as e:
            raise ExtensionError(f"LKQL class not found: {cls_name}", e)

        return []


def process_lkql_classes_coverage(app, doctree, fromdocname):
    """
    Process the coverage of lkql classes in documentation. This will print
    warnings for every non-documented class.
    """
    try:
        for cls in lkql_classes:
            if issubclass(cls, liblkqllang.LKQLNodeBaseList):
                continue
            if not is_class_documented(cls):
                print(f"Class not documented: {cls}")
    except Exception as e:
        traceback.print_exception(type(e), e, e.__traceback__)


def setup(app):
    app.add_directive('lkql_doc_class', LKQLDocClassDirective)
    app.connect('doctree-resolved', process_lkql_classes_coverage)

    return {
        'version': '0.1',
        'parallel_read_safe': True,
        'parallel_write_safe': True,
    }
