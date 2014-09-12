require 'parslet'
include Parslet

module Nodus
  class CoreParser < Parslet::Parser
    root(:nodus)

    rule(:nodus)         { _? >> statement.repeat }
    #rule(:statement) { _? >> lhs >> _? >> rhs >> _? }

    rule(:statement) { str('asdf').as(:statement) >> _? } # TODO: remove me







    #--------- Comments and whitespace -----------------------------------

    rule(:_)              { (ws | comment).repeat(1) }
    rule(:_?)             { (ws | comment).repeat    }

    rule(:comment)        { block_comment | inline_comment }
    rule(:block_comment)  { str('#|') >> ((block_comment | str('|#')).absent? >> any).repeat >> str('|#') }
    rule(:inline_comment) { match['#'] >> (newline.absent? >> any).repeat >> (newline | eof) }

    rule(:newline)        { match[' \t\v\r'].repeat >> match['\n'] >> match['\r\n'].repeat }
    rule(:ws)             { match['\n\r\s\t\v'] }
    rule(:eof)            { any.absent? }
  end
end
