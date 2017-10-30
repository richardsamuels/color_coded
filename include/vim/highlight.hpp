#pragma once

#include <string>
#include <vector>
#include <iostream>

#include "vim/commands.hpp"

namespace color_coded
{
  namespace vim
  {
    struct highlight
    {
      highlight() = delete;
      highlight(std::string const &ty, std::size_t const l,
                std::size_t const c, std::string const &tok)
        : type{ ty }
        , line{ l }
        , column{ c }
        , token{ tok }
      { }

      std::string type;
      std::size_t line, column;
      std::string token;
    };

    class highlight_group
    {
      public:
        using vec_t = std::vector<highlight>;
        using iterator = vec_t::iterator;
        using const_iterator = vec_t::const_iterator;
        using size_type = std::size_t;

        highlight_group() = default;
        // TODO:GOLANG highlight group for golang
        //highlight_group() {
        //      emplace_back(mapped, line, column, spell.c_str());

        //}

        template <typename... Args>
        void emplace_back(Args &&...args)
        { group_.emplace_back(std::forward<Args>(args)...); }

        bool empty() const
        { return group_.empty(); }
        size_type size() const
        { return group_.size(); }

        iterator begin()
        { return group_.begin(); }
        const_iterator begin() const
        { return group_.begin(); }
        const_iterator cbegin() const
        { return group_.cbegin(); }
        iterator end()
        { return group_.end(); }
        const_iterator end() const
        { return group_.end(); }
        const_iterator cend() const
        { return group_.cend(); }

      private:
        std::vector<highlight> group_;
    };
  }
}
