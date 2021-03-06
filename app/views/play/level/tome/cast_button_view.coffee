View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/cast_button'
{me} = require 'lib/auth'

module.exports = class CastButtonView extends View
  id: 'cast-button-view'
  template: template

  subscriptions:
    'tome:spell-changed': "onSpellChanged"
    'tome:cast-spells': 'onCastSpells'
    'god:world-load-progress-changed': 'onWorldLoadProgressChanged'
    'god:new-world-created': 'onNewWorld'

  constructor: (options) ->
    super options
    @spells = options.spells
    isMac = navigator.platform.toUpperCase().indexOf('MAC') isnt -1
    @castShortcut = "⇧↩"
    @castShortcutVerbose = "Shift+Enter"

  getRenderData: (context={}) =>
    context = super context
    context.castShortcutVerbose = @castShortcutVerbose
    context


  afterRender: ->
    super()
    # TODO: use a User setting instead of localStorage
    @hookUpButtons()
    delay = localStorage.getItem 'autocastDelay'
    delay ?= 5000
    @setAutocastDelay delay

  hookUpButtons: ->
    # hook up cast button callbacks
    @castButton = $('.cast-button', @$el)
    @castButtonGroup = $('.cast-button-group', @$el)
    @castOptions = $('.autocast-delays', @$el)

    @castButton.click (e) =>
      Backbone.Mediator.publish 'tome:manual-cast', {}
    @castOptions.find('a').click (e) =>
      Backbone.Mediator.publish 'focus-editor'
      @castButtonGroup.removeClass 'open'
      @setAutocastDelay $(e.target).attr 'data-delay'
      false

  onSpellChanged: (e) ->
    @updateCastButton()

  onCastSpells: (e) ->
    @casting = true
    @updateCastButton()

  onWorldLoadProgressChanged: (e) ->
    overlay = @castButtonGroup.find '.button-progress-overlay'
    overlay.css 'width', e.progress * @castButtonGroup.width()

  onNewWorld: (e) ->
    @casting = false
    @updateCastButton()

  updateCastButton: ->
    return if _.some @spells, (spell) => not spell.loaded
    castable = _.some @spells, (spell) => spell.hasChangedSignificantly spell.getSource()
    @castButtonGroup.toggleClass('castable', castable).toggleClass('casting', @casting)
    if @casting
      s = $.i18n.t("play_level.tome_cast_button_casting", defaultValue: "Casting")
    else if castable
      s = $.i18n.t("play_level.tome_cast_button_castable", defaultValue: "Cast") + " " + @castShortcut
    else
      s = $.i18n.t("play_level.tome_cast_button_cast", defaultValue: "Spell Cast")
    @castButton.text s
    @castButton.prop 'disabled', not castable

  setAutocastDelay: (delay) ->
    #console.log "Set autocast delay to", delay
    return unless delay
    @autocastDelay = delay = parseInt delay
    localStorage.setItem 'autocastDelay', delay
    spell.view.setAutocastDelay delay for spellKey, spell of @spells
    @castOptions.find('a').each ->
      $(@).toggleClass('selected', parseInt($(@).attr('data-delay')) is delay)

  destroy: ->
    super()
