#include <stdlib.h>
#include <stdint.h>
#include <string>

#include "golang.h"
#include "vim/highlight.hpp"

extern "C" {
void InsertHighlight(struct Callback c, char * type, int line, int column,
        char * token) {
    using color_coded::vim::highlight_group;
    highlight_group *h = static_cast<highlight_group*>(c.data_ptr);

    h->emplace_back(type, line, column, token);

    free(type);
    free(token);
}

void Errored(struct Callback c, char * msg) {
    std::string *s = static_cast<std::string*>(c.err_str);

    if(msg != nullptr) {
        *s = msg;
        free(msg);

    }else {
        *s = "Go Runtime panicked with no error message";
    }
}
}
