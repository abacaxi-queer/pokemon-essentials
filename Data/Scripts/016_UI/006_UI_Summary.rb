#===============================================================================
#
#===============================================================================
class MoveSelectionSprite < Sprite
  attr_reader :preselected
  attr_reader :index

  def initialize(viewport = nil, fifthmove = false)
    super(viewport)
    @movesel = AnimatedBitmap.new("Graphics/UI/Summary/cursor_move")
    @frame = 0
    @index = 0
    @fifthmove = fifthmove
    @preselected = false
    @updating = false
    refresh
  end

  def dispose
    @movesel.dispose
    super
  end

  def index=(value)
    @index = value
    refresh
  end

  def preselected=(value)
    @preselected = value
    refresh
  end

  def refresh
    w = @movesel.width
    h = @movesel.height / 2
    self.x = 240
    self.y = 92 + (self.index * 64)
    self.y -= 76 if @fifthmove
    self.y += 20 if @fifthmove && self.index == Pokemon::MAX_MOVES   # Add a gap
    self.bitmap = @movesel.bitmap
    if self.preselected
      self.src_rect.set(0, h, w, h)
    else
      self.src_rect.set(0, 0, w, h)
    end
  end

  def update
    @updating = true
    super
    @movesel.update
    @updating = false
    refresh
  end
end

#===============================================================================
#
#===============================================================================
class RibbonSelectionSprite < MoveSelectionSprite
  def initialize(viewport = nil)
    super(viewport)
    @movesel = AnimatedBitmap.new("Graphics/UI/Summary/cursor_ribbon")
    @frame = 0
    @index = 0
    @preselected = false
    @updating = false
    @spriteVisible = true
    refresh
  end

  def visible=(value)
    super
    @spriteVisible = value if !@updating
  end

  def refresh
    w = @movesel.width
    h = @movesel.height / 2
    self.x = 228 + ((self.index % 4) * 68)
    self.y = 76 + ((self.index / 4).floor * 68)
    self.bitmap = @movesel.bitmap
    if self.preselected
      self.src_rect.set(0, h, w, h)
    else
      self.src_rect.set(0, 0, w, h)
    end
  end

  def update
    @updating = true
    super
    self.visible = @spriteVisible && @index >= 0 && @index < 12
    @movesel.update
    @updating = false
    refresh
  end
end

#===============================================================================
#
#===============================================================================
class PokemonSummary_Scene
  MARK_WIDTH  = 19
  MARK_HEIGHT = 19
  # Colors used for messages in this scene
  RED_TEXT_BASE     = Color.new(248, 56, 32)
  RED_TEXT_SHADOW   = Color.new(224, 152, 144)
  BLACK_TEXT_BASE   = Color.new(64, 64, 64)
  BLACK_TEXT_SHADOW = Color.new(176, 176, 176)

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(party, partyindex, inbattle = false)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @party      = party
    @partyindex = partyindex
    @pokemon    = @party[@partyindex]
    @inbattle   = inbattle
    @page = 1
    @typebitmap    = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
    @markingbitmap = AnimatedBitmap.new("Graphics/UI/Summary/markings")
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["pokemon"] = PokemonSprite.new(@viewport)
    @sprites["pokemon"].setOffset(PictureOrigin::CENTER)
    @sprites["pokemon"].x = 104
    @sprites["pokemon"].y = 206
    @sprites["pokemon"].setPokemonBitmap(@pokemon)
    @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
    @sprites["pokeicon"].setOffset(PictureOrigin::CENTER)
    @sprites["pokeicon"].x       = 46
    @sprites["pokeicon"].y       = 92
    @sprites["pokeicon"].visible = false
    @sprites["itemicon"] = ItemIconSprite.new(48, 418, @pokemon.item_id, @viewport)
    @sprites["itemicon"].blankzero = true
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["movepresel"] = MoveSelectionSprite.new(@viewport)
    @sprites["movepresel"].visible     = false
    @sprites["movepresel"].preselected = true
    @sprites["movesel"] = MoveSelectionSprite.new(@viewport)
    @sprites["movesel"].visible = false
    @sprites["ribbonpresel"] = RibbonSelectionSprite.new(@viewport)
    @sprites["ribbonpresel"].visible     = false
    @sprites["ribbonpresel"].preselected = true
    @sprites["ribbonsel"] = RibbonSelectionSprite.new(@viewport)
    @sprites["ribbonsel"].visible = false
    @sprites["uparrow"] = AnimatedSprite.new("Graphics/UI/up_arrow", 8, 28, 40, 2, @viewport)
    @sprites["uparrow"].x = 350
    @sprites["uparrow"].y = 56
    @sprites["uparrow"].play
    @sprites["uparrow"].visible = false
    @sprites["downarrow"] = AnimatedSprite.new("Graphics/UI/down_arrow", 8, 28, 40, 2, @viewport)
    @sprites["downarrow"].x = 350
    @sprites["downarrow"].y = 260
    @sprites["downarrow"].play
    @sprites["downarrow"].visible = false
    @sprites["markingbg"] = IconSprite.new(260, 88, @viewport)
    @sprites["markingbg"].setBitmap("Graphics/UI/Summary/overlay_marking")
    @sprites["markingbg"].visible = false
    @sprites["markingoverlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["markingoverlay"].visible = false
    pbSetSystemFont(@sprites["markingoverlay"].bitmap)
    @sprites["markingsel"] = IconSprite.new(0, 0, @viewport)
    @sprites["markingsel"].setBitmap("Graphics/UI/Summary/cursor_marking")
    @sprites["markingsel"].src_rect.height = @sprites["markingsel"].bitmap.height / 2
    @sprites["markingsel"].visible = false
    @sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
    @sprites["messagebox"].viewport       = @viewport
    @sprites["messagebox"].visible        = false
    @sprites["messagebox"].letterbyletter = true
    pbBottomLeftLines(@sprites["messagebox"], 2)
    @nationalDexList = [:NONE]
    GameData::Species.each_species { |s| @nationalDexList.push(s.species) }
    drawPage(@page)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end
  
  def pbStartForgetScene(party, partyindex, move_to_learn)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @party      = party
    @partyindex = partyindex
    @pokemon    = @party[@partyindex]
    @page = 4
    @typebitmap = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
    @sprites["pokeicon"].setOffset(PictureOrigin::CENTER)
    @sprites["pokeicon"].x       = 46
    @sprites["pokeicon"].y       = 92
    @sprites["movesel"] = MoveSelectionSprite.new(@viewport, !move_to_learn.nil?)
    @sprites["movesel"].visible = false
    @sprites["movesel"].visible = true
    @sprites["movesel"].index   = 0
    new_move = (move_to_learn) ? Pokemon::Move.new(move_to_learn) : nil
    drawSelectedMove(new_move, @pokemon.moves[0])
    pbFadeInAndShow(@sprites)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @typebitmap.dispose
    @markingbitmap&.dispose
    @viewport.dispose
  end

  def pbDisplay(text)
    @sprites["messagebox"].text = text
    @sprites["messagebox"].visible = true
    pbPlayDecisionSE
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["messagebox"].busy?
        if Input.trigger?(Input::USE)
          pbPlayDecisionSE if @sprites["messagebox"].pausing?
          @sprites["messagebox"].resume
        end
      elsif Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
        break
      end
    end
    @sprites["messagebox"].visible = false
  end

  def pbConfirm(text)
    ret = -1
    @sprites["messagebox"].text    = text
    @sprites["messagebox"].visible = true
    using(cmdwindow = Window_CommandPokemon.new([_INTL("Yes"), _INTL("No")])) do
      cmdwindow.z       = @viewport.z + 1
      cmdwindow.visible = false
      pbBottomRight(cmdwindow)
      cmdwindow.y -= @sprites["messagebox"].height
      loop do
        Graphics.update
        Input.update
        cmdwindow.visible = true if !@sprites["messagebox"].busy?
        cmdwindow.update
        pbUpdate
        if !@sprites["messagebox"].busy?
          if Input.trigger?(Input::BACK)
            ret = false
            break
          elsif Input.trigger?(Input::USE) && @sprites["messagebox"].resume
            ret = (cmdwindow.index == 0)
            break
          end
        end
      end
    end
    @sprites["messagebox"].visible = false
    return ret
  end

  def pbShowCommands(commands, index = 0)
    ret = -1
    using(cmdwindow = Window_CommandPokemon.new(commands)) do
      cmdwindow.z = @viewport.z + 1
      cmdwindow.index = index
      pbBottomRight(cmdwindow)
      loop do
        Graphics.update
        Input.update
        cmdwindow.update
        pbUpdate
        if Input.trigger?(Input::BACK)
          pbPlayCancelSE
          ret = -1
          break
        elsif Input.trigger?(Input::USE)
          pbPlayDecisionSE
          ret = cmdwindow.index
          break
        end
      end
    end
    return ret
  end

  def drawMarkings(bitmap, x, y)
    mark_variants = @markingbitmap.bitmap.height / MARK_HEIGHT
    markings = @pokemon.markings
    markrect = Rect.new(0, 0, MARK_WIDTH, MARK_HEIGHT)
    (@markingbitmap.bitmap.width / MARK_WIDTH).times do |i|
      markrect.x = i * MARK_WIDTH
      markrect.y = [(markings[i] || 0), mark_variants - 1].min * MARK_HEIGHT
      bitmap.blt(x + (i * MARK_WIDTH), y, @markingbitmap.bitmap, markrect)
    end
  end

  def drawPage(page)
    if PluginManager.installed?("Modular UI Scenes")      
      setPages # Gets the list of pages and current page ID.
		  suffix = UIHandlers.get_info(:summary, @page_id, :suffix)
		  @sprites["background"].setBitmap("Graphics/UI/Summary/bg_#{suffix}")
		  @sprites["pokemon"].setPokemonBitmap(@pokemon)
		  @sprites["pokeicon"].pokemon = @pokemon
		  @sprites["itemicon"].item = @pokemon.item_id
		  overlay = @sprites["overlay"].bitmap
		  overlay.clear
		  base   = Color.new(248, 248, 248)
		  shadow = Color.new(104, 104, 104)
		  drawPageIcons # Draws the page icons.
		  imagepos = []
		  # Draws general page info.
		  ballimage = sprintf("Graphics/UI/Summary/icon_ball_%s", @pokemon.poke_ball)
		  imagepos.push([ballimage, 14, 60])
		  pagename = UIHandlers.get_info(:summary, @page_id, :name)
		  textpos = [
		    [pagename, 26, 22, :left, base, shadow],
		    [@pokemon.name, 46, 68, :left, base, shadow],
		    [_INTL("Item"), 16, 344, :left, base, shadow]
		  ]
		  if @pokemon.hasItem?
		    textpos.push([@pokemon.item.name, 96, 358+54, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)])
		  else
		    textpos.push([_INTL("None"), 96, 358+54, :left, Color.new(192, 200, 208), Color.new(208, 216, 224)])
		  end
		  # Draws additional info for non-Egg Pokemon.
		  if !@pokemon.egg?
		    status = -1
		    if @pokemon.fainted?
			    status = GameData::Status.count - 1
		    elsif @pokemon.status != :NONE
			    status = GameData::Status.get(@pokemon.status).icon_position
		    elsif @pokemon.pokerusStage == 1
			    status = GameData::Status.count
		    end
		    if status >= 0
			    imagepos.push(["Graphics/UI/statuses", 124, 100, 0, 16 * status, 44, 16])
		    end
		    if @pokemon.pokerusStage == 2
			    imagepos.push(["Graphics/UI/Summary/icon_pokerus", 176, 100])
		    end
		    imagepos.push(["Graphics/UI/shiny", 218, 338]) if @pokemon.shiny?
		    textpos.push([@pokemon.level.to_s, 46, 98, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)])
		    if @pokemon.male?
			    textpos.push([_INTL("♂"), 178, 68, :left, Color.new(24, 112, 216), Color.new(136, 168, 208)])
		    elsif @pokemon.female?
			    textpos.push([_INTL("♀"), 178, 68, :left, Color.new(248, 56, 32), Color.new(224, 152, 144)])
		    end
		  end
		  # Draws the page.
		  pbDrawImagePositions(overlay, imagepos)
		  pbDrawTextPositions(overlay, textpos)
		  UIHandlers.call(:summary, @page_id, "layout", @pokemon, self)
		  drawMarkings(overlay, 104, 339)
      
    else  # plugin not installed, haven't changed the x/y positions here
      if @pokemon.egg?
        drawPageOneEgg
        return
      end
      @sprites["pokemon"].setPokemonBitmap(@pokemon)
      @sprites["pokeicon"].pokemon = @pokemon
      @sprites["itemicon"].item = @pokemon.item_id
      overlay = @sprites["overlay"].bitmap
      overlay.clear
      base   = Color.new(248, 248, 248)
      shadow = Color.new(104, 104, 104)
      # Set background image
      @sprites["background"].setBitmap("Graphics/UI/Summary/bg_#{page}")
      imagepos = []
      # Show the Poké Ball containing the Pokémon
      ballimage = sprintf("Graphics/UI/Summary/icon_ball_%s", @pokemon.poke_ball)
      imagepos.push([ballimage, 14, 60])
      # Show status/fainted/Pokérus infected icon
      status = -1
      if @pokemon.fainted?
        status = GameData::Status.count - 1
      elsif @pokemon.status != :NONE
        status = GameData::Status.get(@pokemon.status).icon_position
      elsif @pokemon.pokerusStage == 1
        status = GameData::Status.count
      end
      if status >= 0
        imagepos.push([_INTL("Graphics/UI/statuses"), 124, 100, 0, 16 * status, 44, 16])
      end
      # Show Pokérus cured icon
      if @pokemon.pokerusStage == 2
        imagepos.push(["Graphics/UI/Summary/icon_pokerus", 176, 100])
      end
      # Show shininess star
      imagepos.push(["Graphics/UI/shiny", 2, 134]) if @pokemon.shiny?
      # Draw all images
      pbDrawImagePositions(overlay, imagepos)
      # Write various bits of text
      pagename = [_INTL("INFO"),
                _INTL("TRAINER MEMO"),
                _INTL("SKILLS"),
                _INTL("MOVES"),
                _INTL("RIBBONS")][page - 1]
      textpos = [
        [pagename, 26, 22, :left, base, shadow],
        [@pokemon.name, 46, 68, :left, base, shadow],
        [@pokemon.level.to_s, 46, 98, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
        [_INTL("Item"), 66, 324, :left, base, shadow]
      ]
      # Write the held item's name
      if @pokemon.hasItem?
        textpos.push([@pokemon.item.name, 16, 358, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)])
      else
        textpos.push([_INTL("None"), 16, 358, :left, Color.new(192, 200, 208), Color.new(208, 216, 224)])
      end
      # Write the gender symbol
      if @pokemon.male?
        textpos.push([_INTL("♂"), 178, 68, :left, Color.new(24, 112, 216), Color.new(136, 168, 208)])
      elsif @pokemon.female?
        textpos.push([_INTL("♀"), 178, 68, :left, Color.new(248, 56, 32), Color.new(224, 152, 144)])
      end
      # Draw all text
      pbDrawTextPositions(overlay, textpos)
      # Draw the Pokémon's markings
      drawMarkings(overlay, 84, 292)
      # Draw page-specific information
      case page
        when 1 then drawPageOne
        when 2 then drawPageTwo
        when 3 then drawPageThree
        when 4 then drawPageFour
        when 5 then drawPageFive
      end
    end 
  end

  # SUMMARY
  def drawPageOne
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    dexNumBase   = (@pokemon.shiny?) ? Color.new(248, 56, 32) : Color.new(64, 64, 64)
    dexNumShadow = (@pokemon.shiny?) ? Color.new(224, 152, 144) : Color.new(176, 176, 176)
    # If a Shadow Pokémon, draw the heart gauge area and bar
    if @pokemon.shadowPokemon?
      shadowfract = @pokemon.heart_gauge.to_f / @pokemon.max_gauge_size
      imagepos = [
        ["Graphics/UI/Summary/overlay_shadow", 224, 240],
        ["Graphics/UI/Summary/overlay_shadowbar", 242, 280, 0, 0, (shadowfract * 248).floor, -1]
      ]
      pbDrawImagePositions(overlay, imagepos)
    end
    # Write various bits of text
    textpos_x = 304
	  species_y = 126
	  type_y = 166
	  ot_y = 206
	  id_y = 246
	  textpos2_x = 600
    textpos = [
      [_INTL("Dex No."), textpos_x, 86, :left, base, shadow],
      [_INTL("Species"), textpos_x, species_y, :left, base, shadow],
      [@pokemon.speciesName, textpos_x+197, species_y, :center, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Type"), textpos_x, type_y, :left, base, shadow],
      [_INTL("OT"), textpos_x, ot_y, :left, base, shadow],
      [_INTL("ID No."), textpos_x, id_y, :left, base, shadow]
    ]
    # Write the Regional/National Dex number
    dexnum = 0
    dexnumshift = false
    if $player.pokedex.unlocked?(-1)   # National Dex is unlocked
      dexnum = @nationalDexList.index(@pokemon.species_data.species) || 0
      dexnumshift = true if Settings::DEXES_WITH_OFFSETS.include?(-1)
    else
      ($player.pokedex.dexes_count - 1).times do |i|
        next if !$player.pokedex.unlocked?(i)
        num = pbGetRegionalNumber(i, @pokemon.species)
        break if num <= 0
        dexnum = num
        dexnumshift = true if Settings::DEXES_WITH_OFFSETS.include?(i)
        break
      end
    end
    if dexnum <= 0
      textpos.push(["???", textpos2_x, 86, :center, dexNumBase, dexNumShadow])
    else
      dexnum -= 1 if dexnumshift
      textpos.push([sprintf("%03d", dexnum), textpos2_x, 86, :center, dexNumBase, dexNumShadow])
    end
    # Write Original Trainer's name and ID number
    if @pokemon.owner.name.empty?
      textpos.push([_INTL("RENTAL"), textpos2_x, ot_y, :center, Color.new(64, 64, 64), Color.new(176, 176, 176)])
      textpos.push(["?????", textpos2_x, 214, :center, Color.new(64, 64, 64), Color.new(176, 176, 176)])
    else
      ownerbase   = Color.new(64, 64, 64)
      ownershadow = Color.new(176, 176, 176)
      case @pokemon.owner.gender
      when 0
        ownerbase = Color.new(24, 112, 216)
        ownershadow = Color.new(136, 168, 208)
      when 1
        ownerbase = Color.new(248, 56, 32)
        ownershadow = Color.new(224, 152, 144)
      end
      textpos.push([@pokemon.owner.name, textpos2_x, ot_y, :center, ownerbase, ownershadow])
      textpos.push([sprintf("%05d", @pokemon.owner.public_id), textpos2_x, 214, :center,
                    Color.new(64, 64, 64), Color.new(176, 176, 176)])
    end
    # Write Exp text OR heart gauge message (if a Shadow Pokémon)
    exp_y = 286
	  nextlvl_y = 326
    if @pokemon.shadowPokemon?
      textpos.push([_INTL("Heart Gauge"), textpos_x, exp_y, :left, base, shadow])
      black_text_tag = shadowc3tag(BLACK_TEXT_BASE, BLACK_TEXT_SHADOW)
      heartmessage = [_INTL("The door to its heart is open! Undo the final lock!"),
                      _INTL("The door to its heart is almost fully open."),
                      _INTL("The door to its heart is nearly open."),
                      _INTL("The door to its heart is opening wider."),
                      _INTL("The door to its heart is opening up."),
                      _INTL("The door to its heart is tightly shut.")][@pokemon.heartStage]
      memo = black_text_tag + heartmessage
      drawFormattedTextEx(overlay, 234, 308, 264, memo)
    else
      endexp = @pokemon.growth_rate.minimum_exp_for_level(@pokemon.level + 1)
      textpos.push([_INTL("Exp. Points"), textpos_x, exp_y, :left, base, shadow])
      textpos.push([@pokemon.exp.to_s_formatted, textpos2_x, exp_y, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)])
      textpos.push([_INTL("To Next Lv."), textpos_x, nextlvl_y, :left, base, shadow])
      textpos.push([(endexp - @pokemon.exp).to_s_formatted, textpos2_x, nextlvl_y, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw Pokémon type(s)
    @pokemon.types.each_with_index do |type, i|
      type_number = GameData::Type.get(type).icon_position
      type_rect = Rect.new(0, type_number * 32, 100, 32) # i use bigger icons
      type_x = (@pokemon.types.length == 1) ? 402 : 370 + (95 * i)
      overlay.blt(type_x+30, type_y-5, @typebitmap.bitmap, type_rect)
    end
    # Draw Exp bar
    if @pokemon.level < GameData::GrowthRate.max_level
      file_width = 280
      w = @pokemon.exp_fraction * file_width
      w = ((w / 2).round) * 2
      pbDrawImagePositions(overlay,
                           [["Graphics/UI/Summary/overlay_exp", 309, 368, 0, 0, w, 7]])
    end
  end

  def drawPageOneEgg
    @sprites["itemicon"].item = @pokemon.item_id
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    # Set background image
    @sprites["background"].setBitmap("Graphics/UI/Summary/bg_egg")
    imagepos = []
    # Show the Poké Ball containing the Pokémon
    ballimage = sprintf("Graphics/UI/Summary/icon_ball_%s", @pokemon.poke_ball)
    imagepos.push([ballimage, 14, 60])
    # Draw all images
    pbDrawImagePositions(overlay, imagepos)
    # Write various bits of text
    textpos = [
      [_INTL("TRAINER MEMO"), 26, 22, :left, base, shadow],
      [@pokemon.name, 46, 68, :left, base, shadow],
      [_INTL("Item"), 66, 324, :left, base, shadow]
    ]
    # Write the held item's name
    if @pokemon.hasItem?
      textpos.push([@pokemon.item.name, 16, 358, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)])
    else
      textpos.push([_INTL("None"), 16, 358, :left, Color.new(192, 200, 208), Color.new(208, 216, 224)])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    red_text_tag = shadowc3tag(RED_TEXT_BASE, RED_TEXT_SHADOW)
    black_text_tag = shadowc3tag(BLACK_TEXT_BASE, BLACK_TEXT_SHADOW)
    memo = ""
    # Write date received
    if @pokemon.timeReceived
      date  = @pokemon.timeReceived.day
      month = pbGetMonthName(@pokemon.timeReceived.mon)
      year  = @pokemon.timeReceived.year
      memo += black_text_tag + _INTL("{1} {2}, {3}", date, month, year) + "\n"
    end
    # Write map name egg was received on
    mapname = pbGetMapNameFromId(@pokemon.obtain_map)
    mapname = @pokemon.obtain_text if @pokemon.obtain_text && !@pokemon.obtain_text.empty?
    if mapname && mapname != ""
      mapname = red_text_tag + mapname + black_text_tag
      memo += black_text_tag + _INTL("A mysterious Pokémon Egg received from {1}.", mapname) + "\n"
    else
      memo += black_text_tag + _INTL("A mysterious Pokémon Egg.") + "\n"
    end
    memo += "\n"   # Empty line
    # Write Egg Watch blurb
    memo += black_text_tag + _INTL("\"The Egg Watch\"") + "\n"
    eggstate = _INTL("It looks like this Egg will take a long time to hatch.")
    eggstate = _INTL("What will hatch from this? It doesn't seem close to hatching.") if @pokemon.steps_to_hatch < 10_200
    eggstate = _INTL("It appears to move occasionally. It may be close to hatching.") if @pokemon.steps_to_hatch < 2550
    eggstate = _INTL("Sounds can be heard coming from inside! It will hatch soon!") if @pokemon.steps_to_hatch < 1275
    memo += black_text_tag + eggstate
    # Draw all text
    drawFormattedTextEx(overlay, 232, 86, 268, memo)
    # Draw the Pokémon's markings
    drawMarkings(overlay, 84, 292)
  end

  # TRAINER MEMO
  def drawPageTwo
    overlay = @sprites["overlay"].bitmap
    red_text_tag = shadowc3tag(RED_TEXT_BASE, RED_TEXT_SHADOW)
    black_text_tag = shadowc3tag(BLACK_TEXT_BASE, BLACK_TEXT_SHADOW)
    memo = ""
    # Write nature
    showNature = !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
    if showNature
      nature_name = red_text_tag + @pokemon.nature.name + black_text_tag
      memo += _INTL("{1} nature.", nature_name) + "\n"
    end
    # Write date received
    if @pokemon.timeReceived
      date  = @pokemon.timeReceived.day
      month = pbGetMonthName(@pokemon.timeReceived.mon)
      year  = @pokemon.timeReceived.year
      memo += black_text_tag + _INTL("{1} {2}, {3}", date, month, year) + "\n"
    end
    # Write map name Pokémon was received on
    mapname = pbGetMapNameFromId(@pokemon.obtain_map)
    mapname = @pokemon.obtain_text if @pokemon.obtain_text && !@pokemon.obtain_text.empty?
    mapname = _INTL("Faraway place") if nil_or_empty?(mapname)
    memo += red_text_tag + mapname + "\n"
    # Write how Pokémon was obtained
    mettext = [
      _INTL("Met at Lv. {1}.", @pokemon.obtain_level),
      _INTL("Egg received."),
      _INTL("Traded at Lv. {1}.", @pokemon.obtain_level),
      "",
      _INTL("Had a fateful encounter at Lv. {1}.", @pokemon.obtain_level)
    ][@pokemon.obtain_method]
    memo += black_text_tag + mettext + "\n" if mettext && mettext != ""
    # If Pokémon was hatched, write when and where it hatched
    if @pokemon.obtain_method == 1
      if @pokemon.timeEggHatched
        date  = @pokemon.timeEggHatched.day
        month = pbGetMonthName(@pokemon.timeEggHatched.mon)
        year  = @pokemon.timeEggHatched.year
        memo += black_text_tag + _INTL("{1} {2}, {3}", date, month, year) + "\n"
      end
      mapname = pbGetMapNameFromId(@pokemon.hatched_map)
      mapname = _INTL("Faraway place") if nil_or_empty?(mapname)
      memo += red_text_tag + mapname + "\n"
      memo += black_text_tag + _INTL("Egg hatched.") + "\n"
    else
      memo += "\n"   # Empty line
    end
    # Write characteristic
    if showNature
      best_stat = nil
      best_iv = 0
      stats_order = [:HP, :ATTACK, :DEFENSE, :SPEED, :SPECIAL_ATTACK, :SPECIAL_DEFENSE]
      start_point = @pokemon.personalID % stats_order.length   # Tiebreaker
      stats_order.length.times do |i|
        stat = stats_order[(i + start_point) % stats_order.length]
        if !best_stat || @pokemon.iv[stat] > @pokemon.iv[best_stat]
          best_stat = stat
          best_iv = @pokemon.iv[best_stat]
        end
      end
      characteristics = {
        :HP              => [_INTL("Loves to eat."),
                             _INTL("Takes plenty of siestas."),
                             _INTL("Nods off a lot."),
                             _INTL("Scatters things often."),
                             _INTL("Likes to relax.")],
        :ATTACK          => [_INTL("Proud of its power."),
                             _INTL("Likes to thrash about."),
                             _INTL("A little quick tempered."),
                             _INTL("Likes to fight."),
                             _INTL("Quick tempered.")],
        :DEFENSE         => [_INTL("Sturdy body."),
                             _INTL("Capable of taking hits."),
                             _INTL("Highly persistent."),
                             _INTL("Good endurance."),
                             _INTL("Good perseverance.")],
        :SPECIAL_ATTACK  => [_INTL("Highly curious."),
                             _INTL("Mischievous."),
                             _INTL("Thoroughly cunning."),
                             _INTL("Often lost in thought."),
                             _INTL("Very finicky.")],
        :SPECIAL_DEFENSE => [_INTL("Strong willed."),
                             _INTL("Somewhat vain."),
                             _INTL("Strongly defiant."),
                             _INTL("Hates to lose."),
                             _INTL("Somewhat stubborn.")],
        :SPEED           => [_INTL("Likes to run."),
                             _INTL("Alert to sounds."),
                             _INTL("Impetuous and silly."),
                             _INTL("Somewhat of a clown."),
                             _INTL("Quick to flee.")]
      }
      memo += black_text_tag + characteristics[best_stat][best_iv % 5] + "\n"
    end
    # Write all text
    drawFormattedTextEx(overlay, 304, 86, 310, memo)
  end

  # STATS / ABILITY
  def drawPageThree
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    # Determine which stats are boosted and lowered by the Pokémon's nature
    statshadows = {}
    GameData::Stat.each_main { |s| statshadows[s.id] = shadow }
    if !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
      @pokemon.nature_for_stats.stat_changes.each do |change|
        statshadows[change[0]] = Color.new(136, 96, 72) if change[1] > 0
        statshadows[change[0]] = Color.new(64, 120, 152) if change[1] < 0
      end
    end
    # Write various bits of text
    textpos_x = 304
    textpos = [
      [_INTL("HP"), textpos_x, 86, :center, base, statshadows[:HP]],
      [sprintf("%d/%d", @pokemon.hp, @pokemon.totalhp), 462, 86, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Attack"), textpos_x, 126, :left, base, statshadows[:ATTACK]],
      [@pokemon.attack.to_s, 456, 126, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Defense"), textpos_x, 166, :left, base, statshadows[:DEFENSE]],
      [@pokemon.defense.to_s, 456, 166, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Sp. Atk"), textpos_x, 206, :left, base, statshadows[:SPECIAL_ATTACK]],
      [@pokemon.spatk.to_s, 456, 206, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Sp. Def"), textpos_x, 246, :left, base, statshadows[:SPECIAL_DEFENSE]],
      [@pokemon.spdef.to_s, 456, 246, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Speed"), textpos_x, 286, :left, base, statshadows[:SPEED]],
      [@pokemon.speed.to_s, 456, 286, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Ability"), textpos_x, 328, :left, base, shadow]
    ]
    # Draw ability name and description
    ability = @pokemon.ability
    if ability
      textpos.push([ability.name, 570, 328, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)])
      drawTextEx(overlay, textpos_x, 366, 320, 3, ability.description, Color.new(64, 64, 64), Color.new(176, 176, 176))
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw HP bar
    if @pokemon.hp > 0
      w = @pokemon.hp * 96 / @pokemon.totalhp.to_f
      w = 1 if w < 1
      w = ((w / 2).round) * 2
      hpzone = 0
      hpzone = 1 if @pokemon.hp <= (@pokemon.totalhp / 2).floor
      hpzone = 2 if @pokemon.hp <= (@pokemon.totalhp / 4).floor
      imagepos = [
        ["Graphics/UI/Summary/overlay_hp", 360, 110, 0, hpzone * 6, w, 6]
      ]
      pbDrawImagePositions(overlay, imagepos)
    end
  end

  # MOVES
  def drawPageFour
    overlay = @sprites["overlay"].bitmap
    moveBase   = Color.new(64, 64, 64)
    moveShadow = Color.new(176, 176, 176)
    ppBase   = [moveBase,                # More than 1/2 of total PP
                Color.new(248, 192, 0),    # 1/2 of total PP or less
                Color.new(248, 136, 32),   # 1/4 of total PP or less
                Color.new(248, 72, 72)]    # Zero PP
    ppShadow = [moveShadow,             # More than 1/2 of total PP
                Color.new(144, 104, 0),   # 1/2 of total PP or less
                Color.new(144, 72, 24),   # 1/4 of total PP or less
                Color.new(136, 48, 48)]   # Zero PP
    @sprites["pokemon"].visible  = true
    @sprites["pokeicon"].visible = false
    @sprites["itemicon"].visible = true
    textpos  = []
    imagepos = []
    # Write move names, types and PP amounts for each known move
    xPos = 426
    yPos = 104    
    Pokemon::MAX_MOVES.times do |i|
      move = @pokemon.moves[i]
      if move
        type_number = GameData::Type.get(move.display_type(@pokemon)).icon_position
        imagepos.push([_INTL("Graphics/UI/types"), 318, yPos - 4, 0, type_number * 32, 100, 32])
        textpos.push([move.name, xPos, yPos, :left, moveBase, moveShadow])
        if move.total_pp > 0
          textpos.push([_INTL("PP"), xPos, yPos + 32, :left, moveBase, moveShadow])
          ppfraction = 0
          if move.pp == 0
            ppfraction = 3
          elsif move.pp * 4 <= move.total_pp
            ppfraction = 2
          elsif move.pp * 2 <= move.total_pp
            ppfraction = 1
          end
          textpos.push([sprintf("%d/%d", move.pp, move.total_pp), 540, yPos + 32, :right, ppBase[ppfraction], ppShadow[ppfraction]])
        end
      else
        textpos.push(["-", xPos, yPos, :left, moveBase, moveShadow])
        textpos.push(["--", xPos, yPos + 32, :right, moveBase, moveShadow])
      end
      yPos += 64
    end
    # Draw all text and images
    pbDrawTextPositions(overlay, textpos)
    pbDrawImagePositions(overlay, imagepos)
  end

  def drawPageFourSelecting(move_to_learn)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    moveBase   = Color.new(64, 64, 64)
    moveShadow = Color.new(176, 176, 176)
    ppBase   = [moveBase,                # More than 1/2 of total PP
                Color.new(248, 192, 0),    # 1/2 of total PP or less
                Color.new(248, 136, 32),   # 1/4 of total PP or less
                Color.new(248, 72, 72)]    # Zero PP
    ppShadow = [moveShadow,             # More than 1/2 of total PP
                Color.new(144, 104, 0),   # 1/2 of total PP or less
                Color.new(144, 72, 24),   # 1/4 of total PP or less
                Color.new(136, 48, 48)]   # Zero PP
    # Set background image
    if move_to_learn
      @sprites["background"].setBitmap("Graphics/UI/Summary/bg_learnmove")
    else
      @sprites["background"].setBitmap("Graphics/UI/Summary/bg_movedetail")
    end
    # Write various bits of text
    textpos = [
      [_INTL("MOVES"), 26, 22, :left, base, shadow],
      [_INTL("CATEGORY"), 20, 128, :left, base, shadow],
      [_INTL("POWER"), 20, 160, :left, base, shadow],
      [_INTL("ACCURACY"), 20, 192, :left, base, shadow]
    ]
    imagepos = []
    # Write move names, types and PP amounts for each known move
    yPos = 104
    yPos -= 76 if move_to_learn
    limit = (move_to_learn) ? Pokemon::MAX_MOVES + 1 : Pokemon::MAX_MOVES
    limit.times do |i|
      move = @pokemon.moves[i]
      if i == Pokemon::MAX_MOVES
        move = move_to_learn
        yPos += 20
      end
      if move
        type_number = GameData::Type.get(move.display_type(@pokemon)).icon_position
        imagepos.push([_INTL("Graphics/UI/types"), 318, yPos - 4, 0, type_number * 32, 100, 32])
        textpos.push([move.name, 426, yPos, :left, moveBase, moveShadow])
        if move.total_pp > 0
          textpos.push([_INTL("PP"), 426, yPos + 32, :left, moveBase, moveShadow])
          ppfraction = 0
          if move.pp == 0
            ppfraction = 3
          elsif move.pp * 4 <= move.total_pp
            ppfraction = 2
          elsif move.pp * 2 <= move.total_pp
            ppfraction = 1
          end
          textpos.push([sprintf("%d/%d", move.pp, move.total_pp), 460, yPos + 32, :right,
                        ppBase[ppfraction], ppShadow[ppfraction]])
        end
      else
        textpos.push(["-", 426, yPos, :left, moveBase, moveShadow])
        textpos.push(["--", 426, yPos + 32, :right, moveBase, moveShadow])
      end
      yPos += 64
    end
    # Draw all text and images
    pbDrawTextPositions(overlay, textpos)
    pbDrawImagePositions(overlay, imagepos)
    # Draw Pokémon's type icon(s)
    @pokemon.types.each_with_index do |type, i|
      type_number = GameData::Type.get(type).icon_position
      type_rect = Rect.new(0, type_number * 32, 100, 32)
      type_y = (@pokemon.types.length == 1) ? 70 : 70 + (32 * i)
      overlay.blt(140, type_y, @typebitmap.bitmap, type_rect)
    end
  end

  def drawSelectedMove(move_to_learn, selected_move)
    # Draw all of page four, except selected move's details
    drawPageFourSelecting(move_to_learn)
    # Set various values
    overlay = @sprites["overlay"].bitmap
    base = Color.new(64, 64, 64)
    shadow = Color.new(176, 176, 176)
    @sprites["pokemon"].visible = false if @sprites["pokemon"]
    @sprites["pokeicon"].pokemon = @pokemon
    @sprites["pokeicon"].visible = true
    @sprites["itemicon"].visible = false if @sprites["itemicon"]
    textpos = []
    # Write power and accuracy values for selected move
    case selected_move.display_damage(@pokemon)
    when 0 then textpos.push(["---", 216, 160, :right, base, shadow])   # Status move
    when 1 then textpos.push(["???", 216, 160, :right, base, shadow])   # Variable power move
    else        textpos.push([selected_move.display_damage(@pokemon).to_s, 216, 160, :right, base, shadow])
    end
    if selected_move.display_accuracy(@pokemon) == 0
      textpos.push(["---", 216, 192, :right, base, shadow])
    else
      textpos.push(["#{selected_move.display_accuracy(@pokemon)}%", 216 + overlay.text_size("%").width, 192, :right, base, shadow])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw selected move's damage category icon
    imagepos = [["Graphics/UI/category", 166, 124, 0, selected_move.display_category(@pokemon) * 28, 64, 28]]
    pbDrawImagePositions(overlay, imagepos)
    # Draw selected move's description
    drawTextEx(overlay, 4, 224, 230, 5, selected_move.description, base, shadow)
  end

  # RIBBONS (when script of Ludicrious is not installed)
  def drawPageFive
  if !PluginManager.installed?("Improved Mementos")	  
    overlay = @sprites["overlay"].bitmap
    @sprites["uparrow"].visible   = false
    @sprites["downarrow"].visible = false
    # Write various bits of text
    textpos = [
      [_INTL("No. of Ribbons:"), 294, 429, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [@pokemon.numRibbons.to_s, 550, 429, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)]
    ]
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Show all ribbons
    imagepos = []
    coord = 0
    ribbons_line = 5
    total_ribbons = 25
    ribbon_width = ribbon_height = 78
    (@ribbonOffset * ribbons_line...(@ribbonOffset * ribbons_line) + total_ribbons).each do |i|
	break if !@pokemon.ribbons[i]
	ribbon_data = GameData::Ribbon.get(@pokemon.ribbons[i])
	ribn = ribbon_data.icon_position
	imagepos.push(["Graphics/UI/Summary/ribbons",
		277 + (68 * (coord % ribbons_line)), ribbon_height + (66 * (coord / ribbons_line).floor),
		ribbon_width * (ribn % 8), ribbon_width * (ribn / 8).floor, ribbon_width, ribbon_height])
      coord += 1
    end
    # Draw all images
    pbDrawImagePositions(overlay, imagepos)
  end
  end

  def drawSelectedRibbon(ribbonid)
    # Draw all of page five
    drawPage(5)
    # Set various values
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(64, 64, 64)
    shadow = Color.new(176, 176, 176)
    nameBase   = Color.new(248, 248, 248)
    nameShadow = Color.new(104, 104, 104)
    # Get data for selected ribbon
    name = ribbonid ? GameData::Ribbon.get(ribbonid).name : ""
    desc = ribbonid ? GameData::Ribbon.get(ribbonid).description : ""
    # Draw the description box
    imagepos = [
      ["Graphics/UI/Summary/overlay_ribbon", 0, 335]
    ]
    pbDrawImagePositions(overlay, imagepos)
    # Draw name of selected ribbon
    textpos = [
      [name, 18, 349, :left, nameBase, nameShadow]
    ]
    pbDrawTextPositions(overlay, textpos)
    # Draw selected ribbon's description
    drawTextEx(overlay, 18, 389, 580, 3, desc, base, shadow)
  end

  def pbGoToPrevious
    newindex = @partyindex
    while newindex > 0
      newindex -= 1
      if @party[newindex] && (@page == 1 || !@party[newindex].egg?)
        @partyindex = newindex
        break
      end
    end
  end

  def pbGoToNext
    newindex = @partyindex
    while newindex < @party.length - 1
      newindex += 1
      if @party[newindex] && (@page == 1 || !@party[newindex].egg?)
        @partyindex = newindex
        break
      end
    end
  end

  def pbChangePokemon
    @pokemon = @party[@partyindex]
    @sprites["pokemon"].setPokemonBitmap(@pokemon)
    @sprites["itemicon"].item = @pokemon.item_id
    pbSEStop
    @pokemon.play_cry
  end

  def pbMoveSelection
    @sprites["movesel"].visible = true
    @sprites["movesel"].index   = 0
    selmove    = 0
    oldselmove = 0
    switching = false
    drawSelectedMove(nil, @pokemon.moves[selmove])
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["movepresel"].index == @sprites["movesel"].index
        @sprites["movepresel"].z = @sprites["movesel"].z + 1
      else
        @sprites["movepresel"].z = @sprites["movesel"].z
      end
      if Input.trigger?(Input::BACK)
        (switching) ? pbPlayCancelSE : pbPlayCloseMenuSE
        break if !switching
        @sprites["movepresel"].visible = false
        switching = false
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        if selmove == Pokemon::MAX_MOVES
          break if !switching
          @sprites["movepresel"].visible = false
          switching = false
        elsif !@pokemon.shadowPokemon?
          if switching
            tmpmove                    = @pokemon.moves[oldselmove]
            @pokemon.moves[oldselmove] = @pokemon.moves[selmove]
            @pokemon.moves[selmove]    = tmpmove
            @sprites["movepresel"].visible = false
            switching = false
            drawSelectedMove(nil, @pokemon.moves[selmove])
          else
            @sprites["movepresel"].index   = selmove
            @sprites["movepresel"].visible = true
            oldselmove = selmove
            switching = true
          end
        end
      elsif Input.trigger?(Input::UP)
        selmove -= 1
        if selmove < Pokemon::MAX_MOVES && selmove >= @pokemon.numMoves
          selmove = @pokemon.numMoves - 1
        end
        selmove = 0 if selmove >= Pokemon::MAX_MOVES
        selmove = @pokemon.numMoves - 1 if selmove < 0
        @sprites["movesel"].index = selmove
        pbPlayCursorSE
        drawSelectedMove(nil, @pokemon.moves[selmove])
      elsif Input.trigger?(Input::DOWN)
        selmove += 1
        selmove = 0 if selmove < Pokemon::MAX_MOVES && selmove >= @pokemon.numMoves
        selmove = 0 if selmove >= Pokemon::MAX_MOVES
        selmove = Pokemon::MAX_MOVES if selmove < 0
        @sprites["movesel"].index = selmove
        pbPlayCursorSE
        drawSelectedMove(nil, @pokemon.moves[selmove])
      end
    end
    @sprites["movesel"].visible = false
  end

  def pbRibbonSelection
    @sprites["ribbonsel"].visible = true
    @sprites["ribbonsel"].index   = 0
    selribbon    = @ribbonOffset * 5
    oldselribbon = selribbon
    switching = false
    numRibbons = @pokemon.ribbons.length
    numRows    = [((numRibbons + 4) / 5).floor, 3].max
    drawSelectedRibbon(@pokemon.ribbons[selribbon])
    loop do
      @sprites["uparrow"].visible   = (@ribbonOffset > 0)
      @sprites["downarrow"].visible = (@ribbonOffset < numRows - 4)
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["ribbonpresel"].index == @sprites["ribbonsel"].index
        @sprites["ribbonpresel"].z = @sprites["ribbonsel"].z + 1
      else
        @sprites["ribbonpresel"].z = @sprites["ribbonsel"].z
      end
      hasMovedCursor = false
      if Input.trigger?(Input::BACK)
        (switching) ? pbPlayCancelSE : pbPlayCloseMenuSE
        break if !switching
        @sprites["ribbonpresel"].visible = false
        switching = false
      elsif Input.trigger?(Input::USE)
        if switching
          pbPlayDecisionSE
          tmpribbon                      = @pokemon.ribbons[oldselribbon]
          @pokemon.ribbons[oldselribbon] = @pokemon.ribbons[selribbon]
          @pokemon.ribbons[selribbon]    = tmpribbon
          if @pokemon.ribbons[oldselribbon] || @pokemon.ribbons[selribbon]
            @pokemon.ribbons.compact!
            if selribbon >= numRibbons
              selribbon = numRibbons - 1
              hasMovedCursor = true
            end
          end
          @sprites["ribbonpresel"].visible = false
          switching = false
          drawSelectedRibbon(@pokemon.ribbons[selribbon])
        else
          if @pokemon.ribbons[selribbon]
            pbPlayDecisionSE
            @sprites["ribbonpresel"].index = selribbon - (@ribbonOffset * 4)
            oldselribbon = selribbon
            @sprites["ribbonpresel"].visible = true
            switching = true
          end
        end
      elsif Input.trigger?(Input::UP)
        selribbon -= 5
        selribbon += numRows * 5 if selribbon < 0
        hasMovedCursor = true
        pbPlayCursorSE
      elsif Input.trigger?(Input::DOWN)
        selribbon += 5
        selribbon -= numRows * 5 if selribbon >= numRows * 5
        hasMovedCursor = true
        pbPlayCursorSE
      elsif Input.trigger?(Input::LEFT)
        selribbon -= 1
        selribbon += 5 if selribbon % 5 == 4
        hasMovedCursor = true
        pbPlayCursorSE
      elsif Input.trigger?(Input::RIGHT)
        selribbon += 1
        selribbon -= 5 if selribbon % 5 == 0
        hasMovedCursor = true
        pbPlayCursorSE
      end
      next if !hasMovedCursor
      @ribbonOffset = (selribbon / 5).floor if selribbon < @ribbonOffset * 5
      @ribbonOffset = (selribbon / 5).floor - 2 if selribbon >= (@ribbonOffset + 4) * 5
      @ribbonOffset = 0 if @ribbonOffset < 0
      @ribbonOffset = numRows - 4 if @ribbonOffset > numRows - 4
      @sprites["ribbonsel"].index    = selribbon - (@ribbonOffset * 5)
      @sprites["ribbonpresel"].index = oldselribbon - (@ribbonOffset * 5)
      drawSelectedRibbon(@pokemon.ribbons[selribbon])
    end
    @sprites["ribbonsel"].visible = false
  end

  def pbMarking(pokemon)
    @sprites["markingbg"].visible      = true
    @sprites["markingoverlay"].visible = true
    @sprites["markingsel"].visible     = true
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    ret = pokemon.markings.clone
    markings = pokemon.markings.clone
    mark_variants = @markingbitmap.bitmap.height / MARK_HEIGHT
    index = 0
    redraw = true
    markrect = Rect.new(0, 0, MARK_WIDTH, MARK_HEIGHT)
    loop do
      # Redraw the markings and text
      if redraw
        @sprites["markingoverlay"].bitmap.clear
        (@markingbitmap.bitmap.width / MARK_WIDTH).times do |i|
          markrect.x = i * MARK_WIDTH
          markrect.y = [(markings[i] || 0), mark_variants - 1].min * MARK_HEIGHT
          @sprites["markingoverlay"].bitmap.blt(300 + (58 * (i % 3)), 154 + (50 * (i / 3)),
                                                @markingbitmap.bitmap, markrect)
        end
        textpos = [
          [_INTL("Mark {1}", pokemon.name), 366, 102, :center, base, shadow],
          [_INTL("OK"), 366, 254, :center, base, shadow],
          [_INTL("Cancel"), 366, 304, :center, base, shadow]
        ]
        pbDrawTextPositions(@sprites["markingoverlay"].bitmap, textpos)
        redraw = false
      end
      # Reposition the cursor
      @sprites["markingsel"].x = 284 + (58 * (index % 3))
      @sprites["markingsel"].y = 144 + (50 * (index / 3))
      case index
      when 6   # OK
        @sprites["markingsel"].x = 284
        @sprites["markingsel"].y = 244
        @sprites["markingsel"].src_rect.y = @sprites["markingsel"].bitmap.height / 2
      when 7   # Cancel
        @sprites["markingsel"].x = 284
        @sprites["markingsel"].y = 294
        @sprites["markingsel"].src_rect.y = @sprites["markingsel"].bitmap.height / 2
      else
        @sprites["markingsel"].src_rect.y = 0
      end
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        case index
        when 6   # OK
          ret = markings
          break
        when 7   # Cancel
          break
        else
          markings[index] = ((markings[index] || 0) + 1) % mark_variants
          redraw = true
        end
      elsif Input.trigger?(Input::ACTION)
        if index < 6 && markings[index] > 0
          pbPlayDecisionSE
          markings[index] = 0
          redraw = true
        end
      elsif Input.trigger?(Input::UP)
        if index == 7
          index = 6
        elsif index == 6
          index = 4
        elsif index < 3
          index = 7
        else
          index -= 3
        end
        pbPlayCursorSE
      elsif Input.trigger?(Input::DOWN)
        if index == 7
          index = 1
        elsif index == 6
          index = 7
        elsif index >= 3
          index = 6
        else
          index += 3
        end
        pbPlayCursorSE
      elsif Input.trigger?(Input::LEFT)
        if index < 6
          index -= 1
          index += 3 if index % 3 == 2
          pbPlayCursorSE
        end
      elsif Input.trigger?(Input::RIGHT)
        if index < 6
          index += 1
          index -= 3 if index % 3 == 0
          pbPlayCursorSE
        end
      end
    end
    @sprites["markingbg"].visible      = false
    @sprites["markingoverlay"].visible = false
    @sprites["markingsel"].visible     = false
    if pokemon.markings != ret
      pokemon.markings = ret
      return true
    end
    return false
  end

  def pbOptions
    dorefresh = false
    commands = []
    cmdGiveItem = -1
    cmdTakeItem = -1
    cmdPokedex  = -1
    cmdMark     = -1
    if !@pokemon.egg?
      commands[cmdGiveItem = commands.length] = _INTL("Give item")
      commands[cmdTakeItem = commands.length] = _INTL("Take item") if @pokemon.hasItem?
      commands[cmdPokedex = commands.length]  = _INTL("View Pokédex") if $player.has_pokedex
    end
    commands[cmdMark = commands.length]       = _INTL("Mark")
    commands[commands.length]                 = _INTL("Cancel")
    command = pbShowCommands(commands)
    if cmdGiveItem >= 0 && command == cmdGiveItem
      item = nil
      pbFadeOutIn do
        scene = PokemonBag_Scene.new
        screen = PokemonBagScreen.new(scene, $bag)
        item = screen.pbChooseItemScreen(proc { |itm| GameData::Item.get(itm).can_hold? })
      end
      dorefresh = pbGiveItemToPokemon(item, @pokemon, self, @partyindex) if item
    elsif cmdTakeItem >= 0 && command == cmdTakeItem
      dorefresh = pbTakeItemFromPokemon(@pokemon, self)
    elsif cmdPokedex >= 0 && command == cmdPokedex
      $player.pokedex.register_last_seen(@pokemon)
      pbFadeOutIn do
        scene = PokemonPokedexInfo_Scene.new
        screen = PokemonPokedexInfoScreen.new(scene)
        screen.pbStartSceneSingle(@pokemon.species)
      end
      dorefresh = true
    elsif cmdMark >= 0 && command == cmdMark
      dorefresh = pbMarking(@pokemon)
    end
    return dorefresh
  end

  def pbChooseMoveToForget(move_to_learn)
    new_move = (move_to_learn) ? Pokemon::Move.new(move_to_learn) : nil
    selmove = 0
    maxmove = (new_move) ? Pokemon::MAX_MOVES : Pokemon::MAX_MOVES - 1
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK)
        selmove = Pokemon::MAX_MOVES
        pbPlayCloseMenuSE if new_move
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        break
      elsif Input.trigger?(Input::UP)
        selmove -= 1
        selmove = maxmove if selmove < 0
        if selmove < Pokemon::MAX_MOVES && selmove >= @pokemon.numMoves
          selmove = @pokemon.numMoves - 1
        end
        @sprites["movesel"].index = selmove
        selected_move = (selmove == Pokemon::MAX_MOVES) ? new_move : @pokemon.moves[selmove]
        drawSelectedMove(new_move, selected_move)
      elsif Input.trigger?(Input::DOWN)
        selmove += 1
        selmove = 0 if selmove > maxmove
        if selmove < Pokemon::MAX_MOVES && selmove >= @pokemon.numMoves
          selmove = (new_move) ? maxmove : 0
        end
        @sprites["movesel"].index = selmove
        selected_move = (selmove == Pokemon::MAX_MOVES) ? new_move : @pokemon.moves[selmove]
        drawSelectedMove(new_move, selected_move)
      end
    end
    return (selmove == Pokemon::MAX_MOVES) ? -1 : selmove
  end

  def pbScene
    @pokemon.play_cry
    loop do
      Graphics.update
      Input.update
      pbUpdate
      dorefresh = false
      if Input.trigger?(Input::ACTION)
        pbSEStop
        @pokemon.play_cry
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        if @page == 4
          pbPlayDecisionSE
          pbMoveSelection
          dorefresh = true
        elsif @page == 5
          pbPlayDecisionSE
          pbRibbonSelection
          dorefresh = true
        elsif !@inbattle
          pbPlayDecisionSE
          dorefresh = pbOptions
        end
      elsif Input.trigger?(Input::UP) && @partyindex > 0
        oldindex = @partyindex
        pbGoToPrevious
        if @partyindex != oldindex
          pbChangePokemon
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::DOWN) && @partyindex < @party.length - 1
        oldindex = @partyindex
        pbGoToNext
        if @partyindex != oldindex
          pbChangePokemon
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::LEFT) && !@pokemon.egg?
        oldpage = @page
        @page -= 1
        @page = 1 if @page < 1
        @page = 5 if @page > 5
        if @page != oldpage   # Move to next page
          pbSEPlay("GUI summary change page")
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::RIGHT) && !@pokemon.egg?
        oldpage = @page
        @page += 1
        @page = 1 if @page < 1
        @page = 5 if @page > 5
        if @page != oldpage   # Move to next page
          pbSEPlay("GUI summary change page")
          @ribbonOffset = 0
          dorefresh = true
        end
      end
      drawPage(@page) if dorefresh
    end
    return @partyindex
  end
end

#===============================================================================
#
#===============================================================================
class PokemonSummaryScreen
  def initialize(scene, inbattle = false)
    @scene = scene
    @inbattle = inbattle
  end

  def pbStartScreen(party, partyindex)
    @scene.pbStartScene(party, partyindex, @inbattle)
    ret = @scene.pbScene
    @scene.pbEndScene
    return ret
  end

  def pbStartForgetScreen(party, partyindex, move_to_learn)
    ret = -1
    @scene.pbStartForgetScene(party, partyindex, move_to_learn)
    loop do
      ret = @scene.pbChooseMoveToForget(move_to_learn)
      break if ret < 0 || !move_to_learn
      break if $DEBUG || !party[partyindex].moves[ret].hidden_move?
      pbMessage(_INTL("HM moves can't be forgotten now.")) { @scene.pbUpdate }
    end
    @scene.pbEndScene
    return ret
  end

  def pbStartChooseMoveScreen(party, partyindex, message)
    ret = -1
    @scene.pbStartForgetScene(party, partyindex, nil)
    pbMessage(message) { @scene.pbUpdate }
    loop do
      ret = @scene.pbChooseMoveToForget(nil)
      break if ret >= 0
      pbMessage(_INTL("You must choose a move!")) { @scene.pbUpdate }
    end
    @scene.pbEndScene
    return ret
  end
end

#===============================================================================
#
#===============================================================================
def pbChooseMove(pokemon, variableNumber, nameVarNumber)
  return if !pokemon
  ret = -1
  pbFadeOutIn do
    scene = PokemonSummary_Scene.new
    screen = PokemonSummaryScreen.new(scene)
    ret = screen.pbStartForgetScreen([pokemon], 0, nil)
  end
  $game_variables[variableNumber] = ret
  if ret >= 0
    $game_variables[nameVarNumber] = pokemon.moves[ret].name
  else
    $game_variables[nameVarNumber] = ""
  end
  $game_map.need_refresh = true if $game_map
end
