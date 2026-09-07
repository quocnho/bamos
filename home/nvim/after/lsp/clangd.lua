-- Clangd (C/C++): background index + clang-tidy + header insertion.
return {
  cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
}
