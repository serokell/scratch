// you better have boehm, can't check
#define HAVE_BOEHMGC 1
#include <nix/primops.hh>
#include <nix/eval.hh>
#include <nix/eval-inline.hh>
#include "simdjson.h"
#include <chrono>
#include <ratio>
#include <nix/json-to-value.hh>
using namespace nix;
using namespace simdjson;

static void parseJSON(EvalState & state, const string & s_, Value & v);
static void fromJSONsimd(EvalState & state, const Pos & pos, Value ** args, Value & v) {
    string s = state.forceStringNoCtx(*args[0], pos);
    ::parseJSON(state, s, v);
}
static void hasSimdJson(EvalState & state, const Pos & _pos, Value ** _args, Value & v) {
    mkBool(v, true);
}

static RegisterPrimOp rp1("hasSimdJson", 0, hasSimdJson);
// TODO: undefined behavior (duplicate attr):
static RegisterPrimOp rp2("fromJSON", 1, fromJSONsimd);


static void parse_json(EvalState & state, document::parser::Iterator &pjh, Value & v) {
    switch(pjh.get_type()) { // values: {["slutfnd
    case '{': {
        std::vector<Attr, gc_allocator<Attr> > values;
        if (pjh.down()) {
            values.reserve(5);
            do {
                // pjh is guaranteed string
                Value& v2 = *state.allocValue();
                // todo: check if already sorted
                values.emplace_back(state.symbols.create(std::move(std::string(pjh.get_string(), pjh.get_string_length()))), &v2);
                pjh.move_to_value();
                parse_json(state, pjh, v2);
            } while (pjh.next());
            pjh.up();
        }
        std::sort(values.begin(), values.end());
        // TODO: handle duplicate values
        // TODO: move vector directly into binding
        state.mkAttrs(v, values.size());
        for (auto &&i : values) {
            v.attrs->push_back(i);
        }
        //v.attrs->slurp(values.data(), values.size());
    }; break;
    case '[': {
        ValueVector values = ValueVector();
        if (pjh.down()) {
            do {
                Value& v2 = *state.allocValue();
                values.push_back(&v2);
                parse_json(state, pjh, v2);
            } while (pjh.next());
            pjh.up();
        }
        state.mkList(v, values.size());
        for (size_t n = 0; n < values.size(); ++n) {
            v.listElems()[n] = values[n];
        }
    }; break;
    case '"': {
        // todo: handle null byte
        // todo: debug:
        //mkStringNoCopy(v, pjh.get_string());
        mkString(v, pjh.get_string());
    }; break;
    case 's': case 'l': case 'u':
        mkInt(v, pjh.get_integer()); break;
    case 't': case 'f': mkBool(v, pjh.is_true()); break;
    case 'n': mkNull(v); break;
    case 'd': mkFloat(v, pjh.get_double()); break;
    }
}

static void parseJSON(EvalState & state, const string & s_, Value & v)
{
    using namespace std::chrono;
    high_resolution_clock::time_point t1 = high_resolution_clock::now();
    document::parser parser;
    // todo: check success
    parser.allocate_capacity(s_.length());
    // ugly hack: GC buffer the string_buf so we only allocate once
    // todo: gives wrong results
    // todo: avoid other allocation in allocate_capacity
    //parser.doc.string_buf.reset((unsigned char*)GC_malloc_atomic(ROUNDUP_N(5 * s_.length() / 3 + 32, 64)));
    auto [doc, error] = parser.parse(s_);
    if (error) {
        throw JSONParseError(error_message(error));
    }
    auto iterator = document::iterator(doc);
    high_resolution_clock::time_point t2 = high_resolution_clock::now();
    parse_json(state, iterator, v);
    // todo: realloc to current_string_buf_loc - string_buf bytes
    //parser.doc.string_buf.release();
    high_resolution_clock::time_point t3 = high_resolution_clock::now();
    duration<double> time_span = duration_cast<duration<double>>(t2 - t1);
    duration<double> time_span2 = duration_cast<duration<double>>(t3 - t2);

    printTalkative("json parse: %1%s", time_span.count());
    printTalkative("json eval:  %1%s", time_span2.count());
}

