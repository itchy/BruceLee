#! /Users/scott/.rvm/rubies/ruby-1.9.2-p0/bin/ruby
# This is a game written to try to win swag at RDRC2
# Point of the game -- kill oponet
# How to kill enemy 
#   All attacks result in the same damge to both parties,
#   So the only way to gain an advantage is by timing the loading of progrmas
#   Programs load 3 at a time, when you are loading you cannot attack or defend
#   So you win by loading programs when your opponent is defending - 
#   or if you have mare A's when you opponet is loading than your opponet does when you are loading you win

# Some basic tenents:
# 1 - Until your starting HP is > 30 run from tough fights, Fight Fair or Easy
# 2 - Always pick the highest attack level you are allowed when loading programs
# 3 - Logic for deciding when to load
#     try to be +2 or greater


# 9 - When upgrades are available select:
#     a) win if available
#     b) upgrade attack


require 'rubygems'
require 'mechanize'
require 'yaml'

# -----------        code notes      ----------------
# form.field_with(:name => 'list').options[0].select
# agent.get('http://someurl.com/').search(".//p[@class='posted']")

# ----      COLOR Terminal        -------
# puts "\e[0;31mRED\e[0m"
# puts "\e[0;32mGREEN\e[0m"

# ----------     BING     -----------
# agent = Mechanize.new
# 
# page = agent.get('http://bing.com/')
# forms = page.forms.select  { |f| f.action =~ /search/i }
# 
# bing_form = forms.first 
# bing_form.q = 'ruby mechanize'
# 
# page_2 = agent.submit(bing_form)
# pp page_2

class Player
  attr_accessor :name, :programs, :life
   
  def initialize(string)
    string.match(/([A-z 642]+):[ ]*([0-9]+HP).+\[(.*)\]/)
    @name = $1
    @life = $2
    @programs = $3.split(/ /) if $3
  end
  
end  

class Dragon
  @@run = 0
  
  def initialize
     @agent = Mechanize.new { |a| a.follow_meta_refresh = true }
     @agent.user_agent_alias = 'Mac Safari'
     @max_attack = 6
  end
  
  
  def enter?
    config = YAML.load_file("twitter.yml")
    login_page = @agent.get("http://reddirtrubyconf.com/auth/twitter")
    form = login_page.forms.first
    form.field_with(:name => "session[password]").value = config["password"]
    form.field_with(:name => "session[username_or_email]").value = config["username"]
    page = @agent.submit(form)
    links = page.links_with(:href => /logout/ )
    links[0]
  end
  
  def create_character
    # I should be at the create a character screen
    page = @agent.get("http://reddirtrubyconf.com/game")
    sleep 1
    character_form = page.forms.first
    character_form["character[name]"] = "ScottJohnson_#{rand(99999)}"
    page = @agent.submit(character_form)
  end
  
  def pick_opponet
    # master class that keeps fighting
    page = fight?(encounter)
    if page
      puts "\e[0;32mYou chose to fight\e[0m"
      load_programs(page)
      moves
    else
      puts "\e[0;32mYou chose to run\e[0m"
      run
    end  
  end
  
  
  def fight?(page)
    type = page.search("div[id=moves]/p:first/b").to_s.strip
    if type[/tough/i]
      false
    else
      page
    end    
  end  
  
  def encounter
    page = @agent.get("http://reddirtrubyconf.com/game/encounter")
  end
  

  
  def load_programs(page)
    # select highest possible attack option
    attack = page.parser.search("select").
             detect {|tag| tag.to_html =~ /program_attack/}.
             children.map {|c| c['value'].to_i}.max         
    defend = 9 - attack         
    
    battle = page.forms.first    
    battle["program_attack"]  = attack
    battle["program_defense"] = defend
    
    @game = @agent.submit(battle)  
    puts "\e[0;34mReloaded with attack=#{attack} defend=#{defend}\e[0m"
  end  
  
  def moves
    me, enemy = @game.parser.search("div#moves p").
                children.select { |p| p.text[/.+:.+HP/] }.
                map {|p| p.text }
    me = Player.new(me) if me
    enemy = Player.new(enemy) if enemy  
    
    if me && enemy
      # HERE -- TURN OFF || ONCE HEALING STARTS    
      if me.programs.empty? # || (enemy.programs[0] && enemy.programs[0].count("A")==0) 
        # reload
        load_programs(@game)
      else
        # execute
        puts "\e[0;34mExecute #{me.name}: #{me.life} - #{me.programs}\n#{enemy.name}: #{enemy.life} - #{enemy.programs}\e[0m"
        @game = @agent.get("http://reddirtrubyconf.com/game/encounter?move=execute")
        # DRY THIS -- 
        me, enemy = @game.parser.search("div#moves p").
                    children.select { |p| p.text[/.+:.+HP/] }.
                    map {|p| p.text }
        me = Player.new(me) if me
        enemy = Player.new(enemy) if enemy
      end  

    
      if me && enemy
        moves
      else
        battle_over
      end
    else
       battle_over
    end  
  end
  
  def battle_over
    # Then you run into…
    # need to evaluate what happens here
    puts "\e[0;32mBATTLE OVER\e[0m"
    # need some unless Matz 
    matz = @game.search("div[id=moves]/p").to_s[/Ruby mastery/]
    if matz
      puts "\e[0;32mMAKE A DECISION\e[0m"
      # Once attack is at 9, AND line 142 has been adjusted just pick HP by commenting out lines 178 & 179
      # COMMENT THE NEXT TWO LINES OUT AT BEGINING OF GAME!    
      @agent.get("http://reddirtrubyconf.com/game/encounter?move=HP")
      pick_opponet
    else 
      puts "\e[0;32mPick next opponent.\e[0m" 
      pick_opponet
    end
  end
  
  def run
    page = @agent.get("http://reddirtrubyconf.com/game/encounter?move=run")
    pick_opponet
  end
  
end  

bruce = Dragon.new
unless bruce.enter?
  # unable to get logged in -- tell user and exit
  puts "\e[0;31mUnalbe to enter the Dragon -- check your twitter account, it may be locked.\e[0m"
  Process::exit(status=true)
end  

# what now
puts "\e[0;32mYou have entered the Dragon -- wrong movie, but...\e[0m"

bruce.create_character
bruce.pick_opponet

  


