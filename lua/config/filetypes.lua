vim.filetype.add {
  extension = {
    html = function(path)
      if vim.fs.root(path, { 'angular.json', 'nx.json' }) then return 'htmlangular' end
      return 'html'
    end,
  },
}
