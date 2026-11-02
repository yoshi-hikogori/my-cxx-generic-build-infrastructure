import my_import_std;

static_assert(my_import_std::module_answer() == 42);

int main() {
	return my_import_std::module_answer() == 42 ? 0 : 1;
}
