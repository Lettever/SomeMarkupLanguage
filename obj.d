import std;

void main() {
	auto a = JSONValue(["1": ["2": ["4": 13]]]);
	auto b = JSONValue(["1": ["2": ["4": 13]]]);
	auto keys = ["1", "2", "3"];

	foo2(a, keys, 14);
	b = foo(b, keys, 14);
	writeln(a == b);
}

JSONValue foo(JSONValue json, string[] keys, int val) {
	if (keys.length == 0) {
		return JSONValue(val);
	}
	if (keys[0] !in json) {
		json[keys[0]] = JSONValue.emptyObject;
	}
	json[keys[0]] = foo(json[keys[0]], keys[1..$], val);
	return json;
}

void foo2(JSONValue json, string[] keys, int val) {
	foreach(i, key; keys.enumerate()) {
		if (i != keys.length - 1) {
			if (key !in json) {
				json[key] = JSONValue.emptyObject;
			}
			json = json[key];
		} else {
			json[key] = val;
		}
	}
}
