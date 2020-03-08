CXXFLAGS := -fPIC -flto -std=c++2a -O3
.SUFFIXES:
.SUFFIXES: .cpp .cc .o .c .h .so
.PHONY: clean install
importzip.so: plugin.o miniz.o
	g++ -shared $(CXXFLAGS) $^ -o $@
clean:
	rm -f *.o *.so
install: importzip.so
	install -Dt ${out}/lib $^
