namespace Birdie {
    public class Birdie : Granite.Application {
        public Widgets.UnifiedWindow m_window;
        public Widgets.TweetList home_list; 
        public Widgets.TweetList mentions_list; 
        public Widgets.TweetList own_list; 
        public Widgets.TweetList user_list; 
        
        private Gtk.ToolButton new_tweet;
        private Gtk.ToolButton home;
        private Gtk.ToolButton mentions;
        private Gtk.ToolButton dm;
        private Gtk.ToolButton profile;
        private Gtk.ToolButton search;
        
        private Gtk.ScrolledWindow scrolled_home;
        private Gtk.ScrolledWindow scrolled_mentions;
        private Gtk.ScrolledWindow scrolled_own;
        private Gtk.ScrolledWindow scrolled_user;
        
        private Granite.Widgets.StaticNotebook notebook;
        private Gtk.Spinner spinner;
        
        private GLib.List<Tweet> home_tmp;
        
        public Twitter api;
        
        public string current_timeline;
        
        construct {
            program_name        = "Birdie";
            exec_name           = "birdie";
            build_version       = Constants.VERSION;
            app_years           = "2013";
            app_icon            = "birdie";
            app_launcher        = "birdie.desktop";
            application_id      = "org.pantheon.birdie";
            main_url            = "http://www.launchpad.net/birdie";
            bug_url             = "http://bugs.launchpad.net/birdie";
            help_url            = "http://answers.launchpad.net/birdie";
            translate_url       = "http://translations.launchpad.net/birdie";
            about_authors       = {"Ivo Nunes <ivo@elementaryos.org>", "Vasco Nunes <vascomfnunes@gmail.com>"};
            /*about_documenters   = {};
            about_artists       = {};
            about_comments      = {};
            about_translators   = {};*/
            about_license_type  = Gtk.License.GPL_3_0;
        }

        public override void activate (){
            if (get_windows () == null) {
                this.m_window = new Widgets.UnifiedWindow ();
                this.m_window.set_default_size (450, 600);
                this.m_window.set_application (this);
                
                this.new_tweet = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("mail-message-new", Gtk.IconSize.LARGE_TOOLBAR), _("New Tweet"));
                new_tweet.set_tooltip_text (_("New Tweet"));
		        new_tweet.clicked.connect (() => {
		            Widgets.TweetDialog dialog = new Widgets.TweetDialog (this); 
			        dialog.show_all ();
		        });
		        new_tweet.set_sensitive (false);
		        this.m_window.add_bar (new_tweet);
		        
		        var left_sep = new Gtk.SeparatorToolItem ();
                left_sep.draw = false;
                left_sep.set_expand (true);
                this.m_window.add_bar (left_sep);
		        
		        this.home = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("twitter-home", Gtk.IconSize.LARGE_TOOLBAR), _("Home"));
		        home.set_tooltip_text (_("Home"));
		        home.clicked.connect (() => {
			        this.switch_timeline ("home");
		        });
		        this.home.set_sensitive (false);
		        this.m_window.add_bar (home);
		        
		        this.mentions = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("twitter-mentions", Gtk.IconSize.LARGE_TOOLBAR), _("Mentions"));
		        mentions.set_tooltip_text (_("Mentions"));
		        mentions.clicked.connect (() => {
			        this.switch_timeline ("mentions");
		        });
		        this.mentions.set_sensitive (false);
		        this.m_window.add_bar (mentions);
		        
		        this.dm = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("twitter-dm", Gtk.IconSize.LARGE_TOOLBAR), _("Direct Messages"));
		        dm.set_tooltip_text (_("Direct Messages"));
		        dm.clicked.connect (() => {
			        this.switch_timeline ("dm");
		        });
		        this.dm.set_sensitive (false);
		        this.m_window.add_bar (dm);
		        
		        this.profile = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("twitter-profile", Gtk.IconSize.LARGE_TOOLBAR), _("Profile"));
		        profile.set_tooltip_text (_("Profile"));
		        profile.clicked.connect (() => {
			        this.switch_timeline ("own");
		        });
		        this.profile.set_sensitive (false);
		        this.m_window.add_bar (profile);
		        
		        this.search = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("twitter-search", Gtk.IconSize.LARGE_TOOLBAR), _("Search"));
		        search.set_tooltip_text (_("Search"));
		        search.clicked.connect (() => {
			        this.switch_timeline ("search");
		        });
		        this.search.set_sensitive (false);
		        this.m_window.add_bar (search);
		        
		        var right_sep = new Gtk.SeparatorToolItem ();
                right_sep.draw = false;
                right_sep.set_expand (true);
                this.m_window.add_bar (left_sep);
                
                var appmenu = create_appmenu (new Gtk.Menu ());
                this.m_window.add_bar (appmenu);
                
                this.home_list = new Widgets.TweetList ();
                this.mentions_list = new Widgets.TweetList ();
                this.own_list = new Widgets.TweetList ();
                this.user_list = new Widgets.TweetList ();
                
                this.scrolled_home = new Gtk.ScrolledWindow (null, null);
                this.scrolled_home.add_with_viewport (home_list);
                this.scrolled_home.get_style_context ().add_class (Granite.StyleClass.CONTENT_VIEW);
                
                this.scrolled_mentions = new Gtk.ScrolledWindow (null, null);
                this.scrolled_mentions.add_with_viewport (mentions_list);
                this.scrolled_mentions.get_style_context ().add_class (Granite.StyleClass.CONTENT_VIEW);
                
                this.scrolled_own = new Gtk.ScrolledWindow (null, null);
                this.scrolled_own.add_with_viewport (own_list);
                this.scrolled_own.get_style_context ().add_class (Granite.StyleClass.CONTENT_VIEW);
                
                this.scrolled_user = new Gtk.ScrolledWindow (null, null);
                this.scrolled_user.add_with_viewport (user_list);
                this.scrolled_user.get_style_context ().add_class (Granite.StyleClass.CONTENT_VIEW);

                this.notebook = new Granite.Widgets.StaticNotebook ();
                this.notebook.set_switcher_visible (false);

                this.spinner = new Gtk.Spinner ();
                this.spinner.set_size_request (32, 32);
                this.spinner.start ();
                
                Gtk.Box spinner_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
                spinner_box.pack_start (new Gtk.Label (""), true, true, 0);
                spinner_box.pack_start (this.spinner, false, false, 0);
                spinner_box.pack_start (new Gtk.Label (""), true, true, 0);

                this.notebook.append_page (spinner_box, new Gtk.Label (_("Loading")));
                this.notebook.append_page (new Gtk.Label (_("In development")), new Gtk.Label (_("Welcome")));
                this.notebook.append_page (this.scrolled_home, new Gtk.Label (_("Home")));
                this.notebook.append_page (this.scrolled_mentions, new Gtk.Label (_("Mentions")));
                this.notebook.append_page (new Gtk.Label (_("In development")), new Gtk.Label (_("Direct Messages")));
                this.notebook.append_page (this.scrolled_own, new Gtk.Label (_("Profile")));
                this.notebook.append_page (this.scrolled_user, new Gtk.Label (_("User")));
                this.notebook.append_page (new Gtk.Label (_("In development")), new Gtk.Label (_("Search")));
                this.notebook.append_page (new Gtk.Label (_("In development")), new Gtk.Label (_("Search Results")));

                this.m_window.add (this.notebook);
                this.m_window.show_all ();
                
                Thread.create<void*> (this.init, true);
            } else {
                this.m_window.present();
            }
        }
        
        private void* init () {
            this.api = new Twitter ();
            this.api.auth ();
            this.api.get_account ();
            this.api.get_home_timeline ();
            this.api.get_mentions_timeline ();
            this.api.get_own_timeline ();

            Gdk.threads_enter ();
            this.api.home_timeline.foreach ((tweet) => {
                this.home_list.append(tweet, this);
	        });
	            
	        this.api.mentions_timeline.foreach ((tweet) => {
                this.mentions_list.append(tweet, this);
	        });
	            
	        this.api.own_timeline.foreach ((tweet) => {
                this.own_list.append(tweet, this);
	        });
	        Gdk.threads_leave ();
	        
	        this.add_timeout_online ();
            this.add_timeout_offline ();
            
            this.current_timeline = "home";
            this.notebook.page = 2;
            
            this.spinner.stop ();
            
            this.new_tweet.set_sensitive (true);
            this.home.set_sensitive (true);
            this.mentions.set_sensitive (true);
            //this.dm.set_sensitive (true);
            this.profile.set_sensitive (true);
            //this.search.set_sensitive (true);
            
            return null;
        }
        
        public void switch_timeline (string new_timeline) {
            switch (new_timeline) {
                case "loading":
                    this.notebook.page = 0;
                    break;
                case "welcome":
                    this.notebook.page = 1;
                    break;
                case "home":
                    this.notebook.page = 2;
                    break;
                case "mentions":
                    this.notebook.page = 3;
                    break;
                case "dm":
                    this.notebook.page = 4;
                    break;
                case "own":
                    this.notebook.page = 5;
                    break;
                case "user":
                    this.notebook.page = 6;
                    break;
                case "search":
                    this.notebook.page = 7;
                    break;
                case "search_result":
                    this.notebook.page = 8;
                    break;
            }
            
            this.current_timeline = new_timeline;
        }
        
        public void add_timeout_offline () {
            GLib.Timeout.add (60000, () => {
                Thread.create<void*> (this.update_dates, true);
                return false;
            });
        }
        
        public void add_timeout_online () {
            GLib.Timeout.add (120000, () => {
                Thread.create<void*> (this.update_timelines, true);
                return false;
            });
        }

        public void* update_dates () {
            this.home_list.update_date ();
            this.mentions_list.update_date ();
            this.add_timeout_offline ();
            return null;
        }
        
        public void* update_timelines () {
            this.update_home ();
            this.update_mentions ();
            this.add_timeout_online ();
            return null;
        }
        
        public void update_home () {
            this.api.get_home_timeline ();
            
            Gdk.threads_enter ();
            this.home_tmp.foreach ((tweet) => {
                this.home_list.remove (tweet);
                this.home_tmp.remove (tweet);
	        });
            
            this.api.home_timeline_since_id.foreach ((tweet) => {
                this.home_list.append(tweet, this);
	        });
	        Gdk.threads_leave ();
        }
        
        public void update_mentions () {
            this.api.get_mentions_timeline ();
            
            Gdk.threads_enter ();
            this.api.mentions_timeline_since_id.foreach ((tweet) => {
                this.mentions_list.append(tweet, this);
	        });
	        Gdk.threads_leave ();
        }
        
        public void tweet_callback (string text, string id = "") {
            int64 code = this.api.update (text, id);
            
            Regex urls = new Regex("((http|https|ftp)://([\\S]+))");
			var text_url = urls.replace(text, -1, 0, "<a href='\\0'>\\0</a>");
            
            if (code != 1) {
                Tweet tweet_tmp = new Tweet (code.to_string (), this.api.account.name, this.api.account.screen_name, text_url, "", this.api.account.profile_image_url, this.api.account.profile_image_file);

                Gdk.threads_enter ();
                this.home_tmp.append (tweet_tmp);
                this.home_list.append (tweet_tmp, this);
                this.own_list.append (tweet_tmp, this);
                Gdk.threads_leave ();
            }
            
            this.notebook.page = 2;
        }
    }
}
