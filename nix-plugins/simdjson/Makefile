CXXFLAGS := -fPIC -flto -std=c++17 -O3 -msse4.2 -mpclmul
.SUFFIXES:
.SUFFIXES: .cpp .cc .o .c .h .so
.PHONY: clean install
simdjson.so: plugin.o simdjson.o
	g++ -shared $(CXXFLAGS) $^ -o $@
clean:
	rm -f *.o *.so
install: simdjson.so
	install -Dt ${out}/lib $^
