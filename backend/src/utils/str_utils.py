def escape_json_string(s: str) -> str:
    char_map = {
        '\a': '\\a',
        '\b': '\\b',
        '\f': '\\f',
        '\n': '\\n',
        '\r': '\\r',
        '\t': '\\t',
        '\v': '\\v',
        # '\\': '\\\\',
        '\"': '\\"',
    }

    s = s.replace('\\', '\\\\')
    for k, v in char_map.items():
        s = s.replace(k, v)
    return s
