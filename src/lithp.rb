class Lisp
  def initialize(ext={})
    @env = { :label => proc { |(name,val), _| @env[name] = eval(val, @env) },
             :car   => lambda { |(list), _| list[0] },
             :cdr   => lambda { |(list), _| list.drop 1 },
             :cons  => lambda { |(e,cell), _| [e] + cell },
             :eq    => lambda { |(l,r), ctx| eval(l, ctx) == cond(r, ctx) },
             :if    => proc { |(cond, thn, els), ctx| eval(cond, ctx) ? eval(thn, ctx) : eval(els, ctx) },
             :atom  => lambda { |(sexpr), _| (sexpr.is_a? Symbol) or (sexpr.is_a? Numeric) },
             :quote => proc { |sexpr, _| sexpr[0] } }.merge(ext)
  end

  def apply fn, args, ctx=@env
    return ctx[fn].call(args, ctx) if ctx[fn].respond_to? :call
    self.eval ctx[fn][2], ctx.merge(Hash[*(ctx[fn][1].zip args).flatten(1)])
  end

  def eval sexpr, ctx=@env
    if ctx[:atom].call [sexpr], ctx
      return ctx[sexpr] || sexpr
    end

    fn, *args = sexpr
    args = args.map { |a| self.eval(a, ctx) } if ctx[fn].is_a?(Array) || (ctx[fn].respond_to?(:lambda?) && ctx[fn].lambda?)
    apply(fn, args, ctx)
  end
end
