import std;

void main() {
    string[] a = [];
    string k = "";
    k ~= "a";
    k ~= "b";
    a ~= k;
    k = "";
    k ~= "f";
    a ~= k;
    k = "";
    writeln(a);
}