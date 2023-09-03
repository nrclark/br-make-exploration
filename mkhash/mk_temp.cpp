#include <cstring>
#include <string>
#include <string_view>
#include <vector>
#include <iostream>
#include <array>

extern "C" {
    #include <gnumake.h>
}
/* ------------------------------------------------------------------------- */

int plugin_is_GPL_compatible;

std::string expand(const std::string &query) {
    char *gmk_result = gmk_expand(query.c_str());
    std::string result(gmk_result);
    gmk_free(gmk_result);
    return result;
}

std::string eval(const std::string &query) {
    char *gmk_result = gmk_expand(query.c_str());
    std::string result(gmk_result);
    gmk_free(gmk_result);
    return result;
}

template <std::string (*T)(const std::string_view &,
          const std::vector<std::string> &)>
char * Adapter(const char *name, unsigned int argc, char **argv)
{
    const std::vector<std::string> args(argv, argv + argc);
    auto result = T(name, args);
    auto response = gmk_alloc(result.size() + 1);

    response[result.size()] = 0;
    memcpy(response, result.c_str(), result.size());
    return response;
}

/* ------------------------------------------------------------------------- */

std::string my_function(const std::string_view &name,
                           const std::vector<std::string> &args) {
    (void) name;
    (void) args;
    std::cout << name << std::endl;

    for (auto &element: args)
    {
        std::cout << "[" << element << "] ";
    }
    std::cout << std::endl;
    return "blub";
}

std::vector<std::string> split_string(const std::string &input) {
    /* Splits a string of space-separated words into a vector. */

    std::vector<std::string> result;
    size_t end = -1;

    while(1) {
        size_t index = input.find_first_not_of(' ', end + 1);

        if (index == std::string::npos) {
            break;
        }

        end = input.find_first_of(' ', index + 1);
        result.emplace_back(input.substr(index, end - index));

        if (end == std::string::npos) {
            break;
        }
    }
    return result;
}

std::string find_variables(const std::string_view &name,
                           const std::vector<std::string> &args) {
    (void) name;
    (void) args;

    std::string query = "$(filter";
    for (auto &arg: args) {
        for (auto &word: split_string(arg)) {
            query.append({' '});
            query.append(word);
            query.append({'%'});
        }
    }
    query += ",$(.VARIABLES))";
    std::cout << query << std::endl;
    return eval(query);
}

/* ------------------------------------------------------------------------- */

extern "C" {
    int mk_temp_gmk_setup (const gmk_floc *floc);
}

int mk_temp_gmk_setup (const gmk_floc *floc)
{
    printf ("mk_temp plugin loaded from %s:%lu\n", floc->filenm, floc->lineno);
    gmk_add_function ("mk-temp", Adapter<my_function>, 0, 0, GMK_FUNC_DEFAULT);
    gmk_add_function ("find_variables", Adapter<find_variables>, 0, 0, GMK_FUNC_DEFAULT);
    return 1;
}
