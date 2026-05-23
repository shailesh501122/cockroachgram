"""
Cursor pagination — used as the default pager.

Cursor (rather than page/offset) avoids the "new posts shift everything down"
problem in social feeds and is O(1) on the database side.
"""
from rest_framework.pagination import CursorPagination as DRFCursorPagination


class CursorPagination(DRFCursorPagination):
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100
    ordering = "-created_at"
