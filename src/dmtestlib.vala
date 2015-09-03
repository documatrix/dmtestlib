namespace Testlib
{
  public static const string VERSION      = "Testlib";
  public static const string PRODUCT_NAME = "1.0.0";

  private string[] temp_files;

  /**
   * This is the default setup method for testcases.
   * It will create an Array which can be used to store temporary files.
   * The temporary files will be deleted by the default_teardown method.
   */
  public static void default_setup( )
  {
    temp_files = { };
  }

  /**
   * This is the default teardown method for testcases.
   * It will delete every file which is stored in the temp_files array.
   */
  public static void default_teardown( )
  {
    for ( int i = 0; i < Testlib.temp_files.length; i ++ )
    {
      if ( FileUtils.test( Testlib.temp_files[ i ], FileTest.EXISTS ) )
      {
        FileUtils.remove( Testlib.temp_files[ i ] );
      }
    }
  }

  /**
   * This method adds the given filename to the temp_files array.
   * @param temp_file A filename of a temporary file which should be deleted by the default_teardown-method.
   */
  public static void add_temp_file( string temp_file )
  {
    assert( Testlib.temp_files != null );
    Testlib.temp_files += temp_file;
  }

  /**
   * This method can be used to create a temporary file for a given content.
   * It will add the filename of the file to the temp_files-array and will return it.
   * @param content The content which should be stored in a new temporary file.
   * @return The filename of the created temporary file (is already added to the temp_files-array)
   */
  public static string create_temp_file( string content )
  {
    string filename = Testlib.get_temp_file( );
    Testlib.add_temp_file( filename );
    try
    {
      assert( FileUtils.set_contents( filename, content ) );
    }
    catch ( FileError fe )
    {
      assert_not_reached( );
    }

    return filename;
  }

  /**
   * This method can be used to create a temporary file for a given content.
   * It will add the filename of the file to the temp_files-array and will return it.
   * @param data The data which should be stored in a new temporary file.
   * @return The filename of the created temporary file (is already added to the temp_files-array)
   */
  public static string create_binary_temp_file( uint8[] data )
  {
    string filename = Testlib.get_temp_file( );
    Testlib.add_temp_file( filename );
    try
    {
      assert( FileUtils.set_data( filename, data ) );
    }
    catch ( FileError fe )
    {
      assert_not_reached( );
    }

    return filename;
  }

  /**
   * This method creates a filename for a temporary file and returns it (will not create the file!)
   * @return An absolute filename for a temporary file
   */
  public static string get_temp_file( )
  {
    return Path.build_path( Path.DIR_SEPARATOR_S, Environment.get_tmp_dir( ), "%lld_%lu.tmp".printf( (int64)Posix.getpid( ), Random.next_int( ) ) );
  }

  /**
   * This Method tests if two uint8 arrays are equal
   *
   * @return true if the arrays are equal, false else
   */
  public static bool uint8_array_equals( uint8[]? first, uint8[]? second )
  {
    // Wenn nur eines der beiden Arrays null ist, sind sie unterschiedlich
    if(
        ( ( first == null ) && ( second != null ) ) ||
        ( ( first != null ) && ( second == null ) )
      )
    {
      return false;
    }

    // Wenn beide null sind sind sie gleich
    // das muss ich hier prüfen, damit ich bei .length kein Problem bekomme
    if( ( first == null ) && ( second == null ) )
    {
      return true;
    }

    // Wenn sie eine unterschiedliche Länge haben, sind sie nicht ident
    if( first.length != second.length )
    {
      return false;
    }

    // Wenn man bis hier her gekommen ist, muss man jeden Wert einzeln prüfen
    for( uint64 u = 0; u < first.length; u++ )
    {
      if( first[ u ] != second[ u ] )
      {
        return false;
      }
    }

    // wenn man hier hin gekommen ist, sind sie ident
    return true;
  }

  /**
   * This Method tests if two string arrays are equal
   * @param first The first string array
   * @param second The second string array
   * @return true if the arrays are equal, false else
   */
  public static bool string_array_equals( string[]? first, string[]? second )
  {
    // Wenn nur eines der beiden Arrays null ist, sind sie unterschiedlich
    if(
        ( ( first == null ) && ( second != null ) ) ||
        ( ( first != null ) && ( second == null ) )
      )
    {
      return false;
    }

    // Wenn beide null sind sind sie gleich
    // das muss ich hier prüfen, damit ich bei .length kein Problem bekomme
    if( ( first == null ) && ( second == null ) )
    {
      return true;
    }

    // Wenn sie eine unterschiedliche Länge haben, sind sie nicht ident
    if( first.length != second.length )
    {
      return false;
    }

    // Wenn man bis hier her gekommen ist, muss man jeden Wert einzeln prüfen
    for( uint64 u = 0; u < first.length; u++ )
    {
      if( first[ u ] != second[ u ] )
      {
        return false;
      }
    }

    // wenn man hier hin gekommen ist, sind sie ident
    return true;
  }


  /**
   * This method tests if the given file is a valid PDF file
   *
   * @param file_name File to test
   */
  public static void assert_file_is_valid_pdf( string file_name )
  {
    GLib.assert( GLib.FileUtils.test( file_name, GLib.FileTest.EXISTS ) );
    GLib.assert( GLib.FileUtils.test( file_name, GLib.FileTest.IS_REGULAR ) );

    FileStream? stream = FileStream.open( file_name, "r" );
    GLib.assert( stream != null );

    string? line = stream.read_line( );

    try
    {
      GLib.Regex regex = new GLib.Regex( "^\\s*%\\s*PDF" );

      /* In der ersten Zeile muss ein %PDF stehen */
      GLib.assert( line != null );
      GLib.assert( regex.match( line ) );
    }
    catch( Error e )
    {
      GLib.assert_not_reached( );
    }
  }


  /**
   * This method tests if the given file is a valid PS file
   *
   * @param file_name File to test
   */
  public static void assert_file_is_valid_ps( string file_name )
  {
    GLib.assert( GLib.FileUtils.test( file_name, GLib.FileTest.EXISTS ) );
    GLib.assert( GLib.FileUtils.test( file_name, GLib.FileTest.IS_REGULAR ) );

    FileStream? stream = FileStream.open( file_name, "r" );
    GLib.assert( stream != null );

    string? line = stream.read_line( );

    try
    {
      GLib.Regex ps_regex = new GLib.Regex( "^\\s*%!\\s*PS" );
      GLib.Regex xrx_regex = new GLib.Regex( "^\\s*%XRXbegin" );

      /* In der ersten Zeile muss ein %!PS oder %XRXbegin stehen */
      GLib.assert( line != null );
      GLib.assert( ps_regex.match( line ) || xrx_regex.match( line ) );
    }
    catch( Error e )
    {
      GLib.assert_not_reached( );
    }
  }
}
