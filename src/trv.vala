using Xml;

public class TestResultViewer
{
  public static const string PRODUCT_NAME       = "TRV - Test Result Viewer";
  public static const string PRODUCT_VERSION    = "1.0.1";


  // Das zu interpretierende result xml
  static string? result_xml         = null;

  // flag ob nur die Version des Test Result Viewer ausgegeben werden soll
  static bool print_version         = false;

  // flag ob nur die fehlgeschlagenen Jobs angezeigt werden sollen
  static bool print_failed_only     = false;

  // flag ob bei fehlgeschlagenen Tests auch die Fehlermeldung mit ausgegeben werden soll
  static bool print_detailed_error  = false;

  /**
   * The maximum test time. If the runtime of a tests was longer than this value, a warning will be output.
   */
  static double maximum_test_time = 1.0;

  const OptionEntry[] entries = {
    { "infile", 'i', 0, OptionArg.STRING, ref result_xml, "Filename of the result XML", "Result XML" },
    { "version", 'v', 0, OptionArg.NONE, ref print_version, "Print Version", null },
    { "failed-only", 'f', 0, OptionArg.NONE, ref print_failed_only, "Print only failed tests", null },
    { "detail", 'd', 0, OptionArg.NONE, ref print_detailed_error, "Print error messages", null },
    { "max-time", 'm', 0, OptionArg.DOUBLE, ref maximum_test_time, "Maximum test time", null },
    { null }
  };


  public static int main( string[] args )
  {
    stdout.printf( "Starting %s, Version %s\n\n", PRODUCT_NAME, PRODUCT_VERSION );

    int return_value = 0;

    // übergebene Parameter auslesen
    try
    {
      GLib.OptionContext context = new GLib.OptionContext( "- " + PRODUCT_NAME + " Version " + PRODUCT_VERSION );
      context.set_help_enabled( true );
      context.add_main_entries( entries, "test" );
      context.parse( ref args );
    }
    catch( GLib.OptionError e )
    {
      terminate( 20, e.message );
    }

    // Es soll nur die Version ausgegeben werden
    if( print_version )
    {
      return 0;
    }

    // Prüfen ob ein valides inputfile gegeben ist
    if( ( result_xml == null ) || ( result_xml == "" ) || ( ! FileUtils.test( result_xml, FileTest.EXISTS ) ) )
    {
      terminate( 25, "No valid result XML given! '%s'".printf( result_xml ?? "null" ) );
    }

    ResultPrinter rp = new ResultPrinter( result_xml, &return_value, print_failed_only, print_detailed_error, maximum_test_time );

    if( ! rp.read( ) )
    {
      // Sollte beim Lesen ein Fehler auftreten, resette ich hier zur Sicherheit ebenfalls die Formatierung
      // falls vor diesem Schritt in der read Methode abgebrochen wird aber bereits eine Ausgabe getätigt wurde
      rp.reset_terminal( );
      terminate( 99, "Could not print result XML!" );
    }

    return return_value;
  }


  /**
   * Terminates TRV with the given exit_code
   *
   * @param exit_code Exit status
   * @param message Message to print before exiting
   */
  public static void terminate( int16 exit_code, string message )
  {
    stderr.printf( "Exitcode: %d, Message: %s\n", exit_code, message );
    Posix.exit( exit_code );
  }
}


/**
 * Helper class to output the result XML in a nicely readably way
 */
public class ResultPrinter
{
  // Result XML
  public string filename;
  // Dieses flag gibt an, ob nur fehlgeschlagene Tests ausgegeben werden sollen (true), oder alle (false)
  public bool print_failed_only;
  // Dieses flag gibt an, ob eine detaillierte Fehlermeldung ausgegbeen werden soll (true, inklusive der Error Message)
  // oder nicht (false)
  public bool print_detailed_error;

  /**
   * The maximum test time. If the runtime of a tests was longer than this value, a warning will be output.
   */
  public double maximum_test_time = 1.0;

  // Diese 3 Variablen werden verwendet um mit zu zählen wie viele Tests gesamt fehlgeschlagen, gut gegangen
  // oder in ein Overtime gelaufen sind
  private uint64 failed = 0;
  private uint64 passed = 0;
  private uint64 warned = 0;

  // Pointer auf den TRV return_value, wird abhängig von fail und warning gesetzt
  // bei Erfolg muss nichts gesetzt werden, da der default Wert 0 ist
  private int* return_value;

  /**
   * Creates a new ResultPrinter.
   * @param filename The result XML filename.
   * @param return_value The return value.
   * @param print_failed_only Determines if failed tests should be printed only.
   * @param print_detailed_error Determines if detailed error messages should be printed.
   * @param maximum_test_time The maximum test time.
   */
  public ResultPrinter( string filename, int* return_value, bool print_failed_only = false, bool print_detailed_error = false, double maximum_test_time = 1.0 )
  {
    this.filename             = filename;
    this.return_value         = return_value;
    this.print_failed_only    = print_failed_only;
    this.print_detailed_error = print_detailed_error;
    this.maximum_test_time    = maximum_test_time;
  }


  /**
   * Handles opening, closing and freeing the memory of the result xml and starts the parsing process.
   *
   * @return true if the document was successfully read, else false
   */
  public bool read( )
  {
    Xml.Doc* doc = Parser.parse_file( this.filename );

    if( doc == null )
    {
      stderr.printf( "File %s not found or permissions missing", this.filename );
      return false;
    }

    // Get the root node. notice the dereferencing operator -> instead of .
    Xml.Node* root = doc->get_root_element( );

    if( root == null )
    {
      // Free the document manually before returning
      delete doc;
      stderr.printf( "The xml file '%s' is empty", this.filename );
      return false;
    }

    // Let's parse those nodes
    this.parse_node( root );

    // Free the document
    delete doc;

    this.reset_terminal( );
    this.print_summary( );

    return true;
  }


  /**
   * Parses the given node to find a testcast
   *
   * @param node The node to parse
   */
  private void parse_node( Xml.Node* node )
  {
    // Loop over the passed node's children
    for( Xml.Node* iter = node->children; iter != null; iter = iter->next )
    {
      // Spaces between tags are also nodes, discard them
      if( iter->type != Xml.ElementType.ELEMENT_NODE )
      {
        continue;
      }

      // Hier wurde ein Testcase gefunden, parsen und ausgeben
      if( iter->name == "testcase" )
      {
        Testcase? testcase = this.parse_testcase( iter );

        if( testcase != null )
        {
          // Prüfen ob die maximal erlaubte Testzeit überschritten wurde
          double tmp_duration = double.parse( testcase.duration );

          if ( tmp_duration > this.maximum_test_time )
          {
            this.warn( testcase );
          }

          // Testergebnis selbst ausgeben
          if( testcase.passed )
          {
            this.pass( testcase );
          }
          else
          {
            this.fail( testcase );
          }
        }
      }
      else
      {
        // Followed by its children nodes
        this.parse_node( iter );
      }
    }
  }


  /**
   * Parses the given testcase node and extracts all usefull information.
   *
   * @param node The testcase node to parse
   *
   * @return A Testcase object with all found parameters set
   */
  private Testcase? parse_testcase( Xml.Node* node )
  {
    Testcase testcase = new Testcase( );

    // Ich befinde mich hier bereits auf dem <testcase> Tag, daher kann ich gleich das Namespace Attribut auslesen
    for( Xml.Attr* prop = node->properties; prop != null; prop = prop->next )
    {
      string attr_name    = prop->name;
      string attr_content = prop->children->content;

      if( attr_name == "path" )
      {
        testcase.namespace = attr_content.substring( 1 );
      }
      // Wenn dieser Testcase übersprungen wurde, kann ich hier abbrechen
      else if( attr_name == "skipped" )
      {
        return null;
      }
    }

    // Status und Duration sind children von testcase
    for( Xml.Node* iter = node->children; iter != null; iter = iter->next )
    {
      // Spaces between tags are also nodes, discard them
      if( iter->type != Xml.ElementType.ELEMENT_NODE )
      {
        continue;
      }

      if( iter->name == "duration" )
      {
        testcase.duration = iter->get_content( );
      }
      else if( iter->name == "error" )
      {
        testcase.message = iter->get_content( );
      }
      else if( iter->name == "status" )
      {
        for( Xml.Attr* prop = iter->properties; prop != null; prop = prop->next )
        {
          string attr_name    = prop->name;
          string attr_content = prop->children->content;

          if( attr_name == "result" )
          {
            if( ( GLib.Version.check( 2, 54 ) == null ) && ( GLib.Version.check( 2, 57, 2 ) != null ) )
            {
              testcase.passed = attr_content != "success";
            }
            else
            {
              testcase.passed = attr_content == "success";
            }
          }
          else if( attr_name == "exit-status" )
          {
            testcase.exit_status = attr_content;
          }
        }
      }
    }

    return testcase;
  }


  /**
   * Prints a test summary to stdout.
   */
  private void print_summary( )
  {
    stdout.printf( "\n" );
    stdout.printf( "   =======       Summary       =======\n" );
    stdout.printf( "   Total number of tests:      %10lld\n", this.passed + this.failed );
    stdout.printf( "   Number of failed tests:     %10lld\n", this.failed );
    stdout.printf( "   Number of passed tests:     %10lld\n", this.passed );
    stdout.printf( "   Number of overtimed tests:  %10lld\n", this.warned );

    if( ( this.failed == 0 ) && ( this.warned == 0 ) )
    {
      stdout.printf( "\n   THAT'S WHAT I AM TALKING ABOUT! :)\n" );
    }
  }


  /**
   * Handles the output of a Testcase with warning status.
   *
   * @param testcase Testcase object to output
   */
  private void warn( Testcase testcase )
  {
    this.warned++;
    stdout.printf( "%c[0;31m%9s %8s s: %s %s\n", (char) 27, "WARN", testcase.duration, "Overtime for", testcase.namespace );

    if( *this.return_value < 3 )
    {
      *this.return_value = 3;
    }
  }


  /**
   * Handles the output of a Testcase with failed status.
   *
   * @param testcase Testcase object to output
   */
  private void fail( Testcase testcase )
  {
    this.failed++;
    stdout.printf( "%c[1;31m%9s %8s s: %s\n", (char) 27, "FAILED", testcase.duration, testcase.namespace );

    if( this.print_detailed_error )
    {
      stdout.printf( "%21s %s\n\n", "Message:", testcase.message );
    }

    if( *this.return_value < 5 )
    {
      *this.return_value = 5;
    }
  }


  /**
   * Handles the output of a Testcase with passed status.
   *
   * @param testcase Testcase object to output
   */
  private void pass( Testcase testcase )
  {
    this.passed++;

    if( this.print_failed_only )
    {
      return;
    }

    stdout.printf( "%c[1;32m%9s %8s s: %s\n", (char) 27, "OK", testcase.duration, testcase.namespace );
  }


  /**
   * Resets all Terminal formating to default.
   */
  public void reset_terminal( )
  {
    stdout.printf( "%c[0m", (char) 27 );
  }
}


/**
 * Helper class to store all usefull information for a testcase.
 */
public class Testcase
{
  // Namespace of the testcase
  public string namespace   = "";
  // Flag that indicates if the test has passed
  public bool passed        = false;
  // duration of the test execution
  public string duration    = "";
  // exit status of the test
  public string exit_status = "";
  // error message if the test has failed
  public string message     = "";

  public Testcase( )
  {
  }
}
