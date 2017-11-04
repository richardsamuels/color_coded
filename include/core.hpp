#pragma once

#include "golang.h"
#include "vim/commands.hpp"
#include "vim/buffer.hpp"

#include "async/queue.hpp"
#include "async/task.hpp"
#include "async/temp_file.hpp"

#include <string>
#include <map>
#include <sstream>

extern "C" {
#include "color_goded_ast.h"
}

/* XXX: It's a shared object to a C lib; I need globals. :| */
namespace color_coded
{
  namespace core
  {
    namespace fs = boost::filesystem;

    std::string const& last_error(std::string const &e);

    inline std::string temp_dir()
    {
      static auto const temp_dir(fs::temp_directory_path());
      static auto const user_dir("color_coded-" + std::to_string(geteuid()) + "/");
      static auto const dir(temp_dir / user_dir);
      static auto const make_dir(fs::create_directory(dir));
      static_cast<void>(make_dir);
      return dir.string();
    }

    auto constexpr * const no_errors("no errors");
    inline void reset_last_error()
    { last_error(no_errors); }
    inline std::string const& last_error(std::string const &e = "")
    {
      static std::string error{ no_errors };
      if(e.size())
      { error = e; }
      return error;
    }

    inline auto& queue()
    {
      static async::queue<async::task, async::result> q
      {
        [](async::task const &t)
        {
          try
          {
            vim::highlight_group h;
            std::string err;
            struct Callback c;
            c.data_ptr= static_cast<void*>(&h);
            c.err_str = static_cast<void*>(&err);

            // blame go for this
            if(!GoGetTokens(const_cast<char*>(t.name.c_str()), c)) {
                last_error("No tokens???");
                return async::result{{}, {}};
            }
            if(!err.empty()) {
                last_error(err);
                return async::result{{}, {}};
            }

            return async::result
            { t.name, std::move(h) };
          }
          catch(std::exception const &e)
          {
            std::stringstream ss;
            ss << "internal error: " << e.what();
            last_error(ss.str());
            return async::result{{}, {}};
          }
          catch(...)
          {
            last_error("unknown compilation error");
            return async::result{{}, {}};
          }
        }
      };

      return q;
    }

    inline auto& buffers()
    {
      static std::map<std::string, vim::buffer> buffers;
      return buffers;
    }
  }
}
