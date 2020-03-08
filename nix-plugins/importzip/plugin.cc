// you better have boehm, can't check
#define HAVE_BOEHMGC 1
#include <nix/config.h>
#include <nix/globals.hh>
#include <nix/store-api.hh>
#include <nix/derivations.hh>
#include <nix/primops.hh>
#include <nix/eval.hh>
#include <nix/eval-inline.hh>
#include "miniz.h"

using namespace nix;
class ZipFileValue
{
    mz_zip_archive zipfile;
    Path path;

    public:
    ZipFileValue(Path & path, const Pos & pos) : path(path) {

        printTalkative("opening zip file '%1%'", path);
        mz_zip_zero_struct(&zipfile);
        if (mz_zip_reader_init_file(&zipfile, path.c_str(), 0) == 0) {
            throw EvalError(format("unable to read zip file '%1%', at %2%")
                % path % pos);
        }
    }
    virtual ~ZipFileValue()
    {
        printTalkative("closing zip file '%1%'", path);
        mz_zip_reader_end(&zipfile);
    };

    // todo: eval cache should be state-specific
#if HAVE_BOEHMGC
    typedef std::map<Path, Value, std::less<Path>, traceable_allocator<std::pair<const Path, Value> > > FileEvalCache;
#else
    typedef std::map<Path, Value> FileEvalCache;
#endif
    FileEvalCache fileEvalCache;

    void readFile(EvalState & state, const Pos & pos, std::string & filename, Value & v) {
        mz_uint32 file_index;
        if (!mz_zip_reader_locate_file_v2(&zipfile, filename.c_str(), NULL, 0, &file_index))
            throw EvalError(format("unable to locate file '%2%/%1%' at %3%")
                % filename % path % pos);
        mz_zip_archive_file_stat file_stat;
        if (!mz_zip_reader_file_stat(&zipfile, file_index, &file_stat))
            return; // TODO: throw
        std::string out_buffer(file_stat.m_uncomp_size+1, 0);
        if (!mz_zip_reader_extract_to_mem(&zipfile, file_index, out_buffer.data(), file_stat.m_uncomp_size, 0)) {
            throw EvalError(format("unable to extract file '%2%/%1%' at %3%")
                % filename % path % pos);
        }
        mkString(v, out_buffer);
    }
    void importFile(EvalState & state, const Pos & pos, std::string & filename, Value & v) {

        Path canonical = path + "/" + filename;
        // todo: parse cache
        FileEvalCache::iterator i;
        if ((i = fileEvalCache.find(canonical)) != fileEvalCache.end()) {
            v = i->second;
            return;
        }
        mz_uint32 file_index;
        if (!mz_zip_reader_locate_file_v2(&zipfile, filename.c_str(), NULL, 0, &file_index))
            throw EvalError(format("unable to locate file '%1%', in zip file %2%, at %3%")
                % filename % path % pos);
        printTalkative("evaluating zipped file '%1%'", filename);
        mz_zip_archive_file_stat file_stat;
        if (!mz_zip_reader_file_stat(&zipfile, file_index, &file_stat))
            return; // TODO: throw
        std::string out_buffer(file_stat.m_uncomp_size+1, 0);
        if (!mz_zip_reader_extract_to_mem(&zipfile, file_index, out_buffer.data(), file_stat.m_uncomp_size, 0)) {
            throw EvalError(format("unable to extract file '%1%', in zip file %2%, at %3%")
                % filename % path % pos);
        }
        // todo: relative paths
        Expr * e = state.parseExprFromString(out_buffer, dirOf(canonical));
        try {
            state.eval(e, v);
        } catch (Error & e) {
            e.addPrefix(format("while evaluating the zipped file '%1%' from '%2%\n:") % filename % path);
            throw;
        }
        fileEvalCache[canonical] = v;
    }
};

// todo: clean cache at some point
static std::unordered_map<Path, ZipFileValue> zip_cache;

static void canImportZip(EvalState & state, const Pos & _pos, Value ** _args, Value & v) {
    mkBool(v, true);
}

/* Load and evaluate an expression from path specified by the
   argument. */
static void prim_zipImport(EvalState & state, const Pos & pos, Value * * args, Value & v)
{
    PathSet context;
    Path path = state.coerceToPath(pos, *args[0], context);

    try {
        state.realiseContext(context);
    } catch (InvalidPathError & e) {
        throw EvalError(format("cannot import '%1%', since path '%2%' is not valid, at %3%")
            % path % e.path % pos);
    }

    Path realPath = state.checkSourcePath(state.toRealPath(path, context));
    if(realPath.ends_with(".zip")) realPath += "/default.nix";
    std::size_t zipLoc = realPath.find(".zip/");
    if (zipLoc != std::string::npos) {
      Path zipPath = realPath.substr(0, zipLoc+4);
      Path filePath = realPath.substr(zipLoc+5);
      auto zip_entry = zip_cache.try_emplace(zipPath, zipPath, pos).first;
      zip_entry->second.importFile(state, pos, filePath, v);
      return;
    }
    state.evalFile(realPath, v);
}

static void prim_zipRead(EvalState & state, const Pos & pos, Value * * args, Value & v)
{
    PathSet context;
    Path path = state.coerceToPath(pos, *args[0], context);

    try {
        state.realiseContext(context);
    } catch (InvalidPathError & e) {
        throw EvalError(format("cannot read '%1%', since path '%2%' is not valid, at %3%")
            % path % e.path % pos);
    }

    Path realPath = state.checkSourcePath(state.toRealPath(path, context));
    std::size_t zipLoc = realPath.find(".zip/");
    if (zipLoc != std::string::npos) {
      Path zipPath = realPath.substr(0, zipLoc+4);
      Path filePath = realPath.substr(zipLoc+5);
      auto zip_entry = zip_cache.try_emplace(zipPath, zipPath, pos).first;
      zip_entry->second.readFile(state, pos, filePath, v);
      return;
    }
    string s = readFile(state.checkSourcePath(state.toRealPath(path, context)));
    if (s.find((char) 0) != string::npos)
        throw Error(format("the contents of the file '%1%' cannot be represented as a Nix string") % path);
    mkString(v, s.c_str());
}

static RegisterPrimOp rp1("canImportZip", 0, canImportZip);
// TODO: undefined behavior (duplicate attr):
static RegisterPrimOp rp2("import", 1, prim_zipImport);
static RegisterPrimOp rp3("readFile", 1, prim_zipRead);
