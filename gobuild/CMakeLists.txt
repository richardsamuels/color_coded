add_custom_target(color_goded_ast.a
    COMMAND ${CMAKE_COMMAND} -E env "CGO_LDFLAGS_ALLOW='-Wl.*'" "CGO_CFLAGS=-I${CG_CPP_INC}" go build -buildmode=c-archive "github.com/richardsamuels/color_goded_ast"
    COMMENT "Running go build"
)

include_directories(
    include
    ${CMAKE_CURRENT_BINARY_DIR}
)

set(CG_GO_A ${CMAKE_CURRENT_BINARY_DIR}/color_goded_ast.a PARENT_SCOPE)
set(CG_GO_INC ${CMAKE_CURRENT_BINARY_DIR} PARENT_SCOPE)
