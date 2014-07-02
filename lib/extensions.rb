require 'ostruct'
require 'pathname'
require 'etc'
require 'set'
require 'digest'
require 'base64'
require 'pp'
#require 'excon'
require 'json'
require 'active_support/all'

# module Excon
#   class Response
#     def success?() @status && @status.to_s[0..0] == '2' end
#     def payload
#       @payload ||= case headers['Content-Type']
#                    when 'application/json' then JSON.parse(body)
#                      # when 'text/html' then  # TODO: when needed, go ahead and give a parsed html as well (nokogiri or something)
#                    else body end
#     end
#   end
# 
#   class Connection
#     def basic_url(more_params={})
#       p = data.merge(more_params)
#       "#{p[:scheme]}://#{p[:host]}/#{p[:path]}"
#     end
# 
#     Excon::HTTP_VERBS.each do |method|
#       class_eval <<-DEF, __FILE__, __LINE__ + 1
#         def #{method}!(params={}, &block)
#           rsp = #{method}(params, &block)
#           raise(IOError, "#{method.to_s.upcase} %s returned a %s : %s" % [basic_url(params), rsp.status, rsp.inspect]) unless rsp.success?
#           rsp
#         end
#       DEF
#     end
#   end
# end

class Set; alias_method :[],:member? end

unless defined?(Path)
  Path = Pathname
  class Pathname
    def self.[](p) Path.new(p) end
    alias old_init initialize
    def initialize(*args) old_init(*args); @rc={}; @rc2={} end
    alias_method :exists?,:exist?
    def to_p()  self             end
    def **  (p) self+p.to_p      end
    def r?  ()  readable_real?   end
    def w?  ()  writable_real?   end
    def x?  ()  executable_real? end
    def rw? ()  r? && w?         end
    def rwx?()  r? && w? && x?   end
    def dir?()  directory?       end
    def ===(p)  real == p.real   end
    def perm?() exp.dir? ? rwx? : rw?               end
    def exp ()  return @exp ||= self.expand_path    end
    def real()  begin exp.realpath rescue exp end   end
    def dir()   (exp.dir? || to_s[-1].chr == '/') ? exp : exp.dirname end
    def dir!()  (exp.mkpath unless exp.dir? rescue return nil); self end
    def glob(g,&b) Path.glob((dir + g.to_s).to_s, File::FNM_DOTMATCH, &b)  end
    def [](p)   glob(p)  end
    #def [](p)   Path.glob((dir + p.to_s).to_s, File::FNM_DOTMATCH)  end
    def older_than?(p) self.stat.mtime < p.stat.mtime end
    def missing?() !self.exist? end
    def as_other(new_dir, new_ext=nil)
      p = new_dir.nil? ? self : (new_dir.to_p + self.basename)
      p = Path[p.to_s.sub(/#{self.extname}$/,'.'+new_ext)] if new_ext
      return p
    end
    def rel(p=nil,home=true)
      p ||= ($pwd || Path.pwd)
      return @rc2[p] if @rc2[p]
      r = abs.rel_path_from(p.abs)
      r = r.sub(ENV['HOME'],'~') if home
      r
    end
    def different_contents?(str) IO.read(self).strip != str.strip end
    def short(p=nil,home=true)
      p ||= ($pwd || Path.pwd)
      return @rc2[p.to_s] if @rc2[p.to_s]
      sr  = real; pr  = p.real
      se  = exp;  pe  = p.exp
      candidates  = [sr.rel_path_from(pr), sr.rel_path_from(pe),
        se.rel_path_from(pr), se.rel_path_from(pe)]
      candidates += [sr.sub(ENV['HOME'],'~'), se.sub(ENV['HOME'],'~')] if home
      @rc2[p.to_s] = candidates.sort_by{|v|v.to_s.size}[0]
    end
    def rel_path_from(p) @rc ||= {}; @rc[p.to_s] ||= relative_path_from(p) end
    def relation_to(p)
      travp = p.rel(self,false).to_s
      if    travp =~ /^(..\/)+..(\/|$)/ then :child
      else  travp =~ /^..\// ? :stranger : :parent end
    end
    def dist_from(p)
      return 0 if self === p
      travp = p.dir.rel(self.dir,false).to_s
      return 1 if travp =~ /^\/?\.\/?$/
      return travp.split('/').size + 1
    end
    #alias old_mm method_missing
    #def method_missing(m,*a,&b) to_s.respond_to?(m) ? to_s.send(m,*a,&b) : old_mm(m,*a,&b) end
    def abs(wd=nil)
      wd ||= ($pwd || Path.pwd); wd = wd.to_s
      s    = self.to_s
      raise ArgumentError.new('Bad working directory- must be absolute') if wd[0].chr != '/'
      if    s.blank? ;                                   return nil
      elsif s[0].chr=='/' ;                              return s
      elsif s[0].chr=='~' && (s[1].nil?||s[1].chr=='/'); _abs_i(s[1..-1], ENV['HOME'])
      elsif s =~ /~([^\/]+)/;                            _abs_i($', Etc.getpwnam($1).dir)
      else                                               _abs_i(s, wd) end
    end

    private
    def _abs_i(p,wd)
      str   = wd + '/' + p ; last  = str[-1].chr
      combo = []
      str.split('/').each do |part|
        case part
        when part.blank?, '.' then next
        when '..' then combo.pop
        else combo << part end
      end
      Path.new('/' + combo.join('/') + (last == '/' ? '/' : ''))
    end
  end

  class String
    def to_p()   Path.new(self) end
    #alias old_mm method_missing
    #def method_missing(m,*a,&b) to_p.respond_to?(m) ? to_p.send(m,*a,&b) : old_mm(m,*a,&b) end
    #def respond_to_missing?(m,p=false) to_p.respond_to?(m,p) end
    def same_path(p) to_p === p end
  end
end

class String
  def last(n=1) self.size < n ? self : self[-n..-1] end
  def numeric?()   true if Float(self) rescue false end
end

class Fixnum
  def numeric?() true end
  def s(p=0,ch='0')
    return ch if self == 0 && !ch.nil?
    p > 0 ? ("%.#{p}f" % self) : self.to_s
  end
end

class Float
  def numeric?() true end
  def s(p=2,ch='0')
    return ch if self == 0.0 && p == 0 && !ch.nil?
    v = self.round
    v = (self > 0.0 ? self.ceil : self.floor) if v == 0 && !ch.nil?
    ret = p > 0 ? ("%.#{p}f" % self) : v.to_s
    (ret =~ /^0+(\.0+)?$/ && !ch.nil?) ? ch : ret
  end
end
