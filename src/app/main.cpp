// #ifdef _CLANGD
// #include <iostream>
// #endif

import std;
import my_import_std;

int main() {
	std::printf("Hello world!\n");
	std::cout << "Module answer: " << my_import_std::module_answer() << '\n';
}
