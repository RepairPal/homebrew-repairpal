require 'formula'

# Formula based on: https://raw.githubusercontent.com/Homebrew/homebrew/a03e0900f1fe419e792bbfdd1777f3ca42ab417f/Library/Formula/sphinx.rb

# At present (2014-11-24), we need to use Sphinx 2.1.9 because we're on an
# archaic version of ThinkingSphinx that breaks on newer versions.
# Unfortunately, libstemmer seems to have been updated upstream and started
# breaking builds of 2.1.9.  So, we lock libstemmer to a working version here.
class Sphinx < Formula
  homepage 'http://www.sphinxsearch.com'
  url 'http://sphinxsearch.com/files/sphinx-2.1.9-release.tar.gz'

  head 'http://sphinxsearch.googlecode.com/svn/trunk/'

  bottle do
    revision 1
  end

  devel do
    url 'http://sphinxsearch.com/files/sphinx-2.2.3-beta.tar.gz'
  end

  option 'mysql', 'Force compiling against MySQL'
  option 'pgsql', 'Force compiling against PostgreSQL'
  option 'id64',  'Force compiling with 64-bit ID support'

  depends_on "re2" => :optional
  depends_on :mysql if build.include? 'mysql'
  depends_on :postgresql if build.include? 'pgsql'

  resource 'stemmer' do
    # Keep this in the repo so it's maintained in lockstep with this formula.
    url 'file://' + Pathname.new(File.expand_path('..', __FILE__))/'libstemmer_c.tgz'
  end

  fails_with :llvm do
    build 2334
    cause "ld: rel32 out of range in _GetPrivateProfileString from /usr/lib/libodbc.a(SQLGetPrivateProfileString.o)"
  end

  fails_with :clang do
    build 421
    cause "sphinxexpr.cpp:1802:11: error: use of undeclared identifier 'ExprEval'"
  end

  def install
    (buildpath/'libstemmer_c').install resource('stemmer')

    # libstemmer changed the name of the non-UTF8 Hungarian source files,
    # but the released version of sphinx still refers to it under the old name.
    inreplace "libstemmer_c/Makefile.in",
      "stem_ISO_8859_1_hungarian", "stem_ISO_8859_2_hungarian"

    args = %W[--prefix=#{prefix}
              --disable-dependency-tracking
              --localstatedir=#{var}
              --with-libstemmer]

    args << "--enable-id64" if build.include? 'id64'
    args << "--with-re2" if build.with? 're2'

    %w{mysql pgsql}.each do |db|
      if build.include? db
        args << "--with-#{db}"
      else
        args << "--without-#{db}"
      end
    end

    system "./configure", *args
    system "make install"
  end

  def caveats; <<-EOS.undent
    Sphinx has been compiled with libstemmer support.

    Sphinx depends on either MySQL or PostreSQL as a datasource.

    You can install these with Homebrew with:
      brew install mysql
        For MySQL server.

      brew install mysql-connector-c
        For MySQL client libraries only.

      brew install postgresql
        For PostgreSQL server.

    We don't install these for you when you install this formula, as
    we don't know which datasource you intend to use.
    EOS
  end
end
