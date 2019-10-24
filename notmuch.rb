class ShellCommand
  attr_accessor :command
  def run(dry: false, verb: false)
    pre_run
    puts @command if dry or verb
    `#{@command}` unless dry
  end
end

class NotmuchTagCommand < ShellCommand
  attr_accessor :ta, :tr, :search_expr
  def initialize(add_list, remove_list, search_expr)
    @ta, @tr, @se = add_list, remove_list, search_expr
  end
  def pre_run
    ta_str = @ta.map {|t| "+" + t}.join(" ")
    tr_str = @tr.map {|t| "-" + t}.join(" ")
    se_str = @se.to_s
    @command = "notmuch tag #{ta_str} #{tr_str} #{se_str}"
  end
end

class NotmuchSearchCommand < ShellCommand
  attr_accessor :search_expr, :options
  def initialize(search_expr, **options)
    @se, @opts = search_expr, options
  end
  def pre_run
    se_str = @se.to_s
    opts_str = @opts.map {|p| "--#{p[0]}=#{p[1]}"}.join(" ")
    @command = "notmuch search #{opts_str} #{se_str}"
  end
end

# Generic notmuch search expression.
#
# Notmuch search expression (or "search term" in the official docs) is
# passed to some notmuch commands (e.g. "notmuch search", "notmuch
# tag") as a syntax for queries.
#
# For example,
#
# To add "sent" tag to those emails that sent FROM one of my email
# addresses but not TO one of my email addresses, one can use:
#
#     mark_sent_expr = And.new(Or.new(*(My_mail_addrs.map {|addr| From.new(addr)})),
#                              Not.new(Or.new(*(My_mail_addrs.map {|addr| To.new(addr)}))))
#     
#     NotmuchTagCommand.new(
#       %w(sent),
#       %w(inbox unread),
#       mark_sent_expr
#     ).run
#
# This translates to the notmuch command below:
#
#     notmuch tag +sent -inbox -unread  '(' from:addr1 or from:addr2 ')'  and not  '(' to:addr1 to:addr2 ')'
#
# See below for concrete search expressions.
class NotmuchSearchExpression
  attr_accessor :op_str, :pri, :subexprs
  def initialize(*subexprs)
    @subexprs = subexprs
  end
end

# Notmuch search expression with multiple operands.
#
# Current supported multiple-operand search expressions are:
#   - "And" expression
#   - "Xor" expression
#   - "Or" expression
#
# For example, an "And" expression is true when all of its operands
# (subexprs) are true.
class NotmuchSearchExpressionOpN < NotmuchSearchExpression
  def to_s
    out = []
    @subexprs.each do |s|
      s_str = s.to_s
      s_str = " '(' #{s_str} ')' " if s.pri < @pri
      out.push s_str
    end
    out.join " #{@op_str} "
  end
end

# Notmuch search expression with single operand.
#
# Current supported single-operand search expression is:
#   - "Not" expression
#
# For example, a "Not" expression is true when its operand (subexpr)
# is true.
class NotmuchSearchExpressionOp1 < NotmuchSearchExpression
  def to_s
    s = @subexprs[0]
    s_str = s.to_s
    s_str = " '(' #{s_str} ')' " if s.pri < @pri
    "#{@op_str} #{s_str}"
  end
end

# Notmuch search expression with no operand.
#
# See "NotmuchSearchExpressionIdentity" for more concrete examples.
class NotmuchSearchExpressionOp0 < NotmuchSearchExpression
  def to_s
    @subexprs[0]
  end
end

class Or < NotmuchSearchExpressionOpN
  def initialize(*subexprs)
    @op_str = "or"
    @pri = 1
    super
  end
end

class Xor < NotmuchSearchExpressionOpN
  def initialize(*subexprs)
    @op_str = "xor"
    @pri = 1
    super
  end
end

class And < NotmuchSearchExpressionOpN
  def initialize(*subexprs)
    @op_str = "and"
    @pri = 2
    super
  end
end

class Not < NotmuchSearchExpressionOp1
  def initialize(subexpr)
    @op_str = "not"
    @pri = 3
    super
  end
end

# Notmuch search expression that is its sub-expression own.
#
# Current supported identity search expressions are:
#   - "From" expression
#   - "To" expression
#   - "Subject" expression
#   - "Tag" expression
#
# For example, a "Subject" expression is translated to
# "subject:blablabla" notmuch search term, true if the mail subject
# matches "blablabla".  And a "Tag" expression is translated to
# "tag:blablabla" notmuch search term, true if the mail is tagged with
# "blablabla".
class NotmuchSearchExpressionIdentity < NotmuchSearchExpressionOp0
  def initialize(subexpr)
    @op_str = ""
    @pri = 4
    super
  end
end

class From < NotmuchSearchExpressionIdentity
  def initialize(addr)
    super "from:" + addr
  end
end

class To < NotmuchSearchExpressionIdentity
  def initialize(addr)
    super "to:" + addr
  end
end

class Subject < NotmuchSearchExpressionIdentity
  def initialize(addr)
    super "subject:" + addr
  end
end

class Tag < NotmuchSearchExpressionIdentity
  def initialize(addr)
    super "tag:" + addr
  end
end
