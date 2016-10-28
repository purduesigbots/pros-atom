{CompositeDisposable} = require 'atom'
{$, View} = require 'atom-space-pen-views'

module.exports =
  class StatusBar extends View
    @content: ->
      @div class: 'pros-status-bar inline-block', =>
        # coffeelint: disable=max_line_length
        @button class: 'btn btn-default', outlet: 'button', => @raw "<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0px\" y=\"0px\" viewBox=\"0 0 100 100\" enable-background=\"new 0 0 100 100\" xml:space=\"preserve\">
<g>
	<polygon fill-rule=\"evenodd\" clip-rule=\"evenodd\" points=\"79.025,41.379 94.225,54.536 50.113,92.98 50.113,92.957
		50.027,93.032 6.107,54.751 21.328,41.485 50.141,83.744 	\"/>
	<polygon fill-rule=\"evenodd\" clip-rule=\"evenodd\" points=\"28.152,28.248 29.031,29.714 71.25,29.714 72.129,28.248
			\"/>
	<polygon fill-rule=\"evenodd\" clip-rule=\"evenodd\"  points=\"38.119,56.539 33.137,42.027 18.916,34.111 	\"/>
	<polygon fill-rule=\"evenodd\" clip-rule=\"evenodd\"  points=\"62.16,56.687 67.291,42.027 81.217,34.258 	\"/>
	<path fill-rule=\"evenodd\" clip-rule=\"evenodd\"  d=\"M50.141,8.605L12.76,25.463h13.438l2.834,4.251H71.25l2.834-4.251
		H87.52L50.141,8.605z M53.072,18.866l-2.932,1.466l-2.932-1.466v-2.932l2.932-1.466l2.932,1.466V18.866z\"/>
	<path fill-rule=\"evenodd\" clip-rule=\"evenodd\"  d=\"M80.496,34.111H19.783l0.121,0.148l18.51,2.783l-0.295,19.496
		l-2.37-2.769L49.408,70.59V52.289c0-0.294,0.293-0.587,0.586-0.587h0.293c0.293,0,0.586,0.293,0.586,0.587V70.59L62.24,56.592
		l-0.08,0.095l-0.293-19.644l18.398-2.648L80.496,34.111z M50.141,48.771c-0.648,0-1.174-0.524-1.174-1.173
		c0-0.647,0.525-1.173,1.174-1.173c0.646,0,1.172,0.525,1.172,1.173C51.313,48.246,50.787,48.771,50.141,48.771z M50.141,43.787
		c-0.648,0-1.174-0.525-1.174-1.174c0-0.647,0.525-1.173,1.174-1.173c0.646,0,1.172,0.525,1.172,1.173
		C51.313,43.262,50.787,43.787,50.141,43.787z M50.141,38.655c-0.648,0-1.174-0.524-1.174-1.172s0.525-1.173,1.174-1.173
		c0.646,0,1.172,0.525,1.172,1.173S50.787,38.655,50.141,38.655z\"/>
</g>
</svg>"
# coffeelint: enable=max_line_length

    initialize: (@statusBarProvider) ->
      @button[0].firstChild.onclick = @button.onclick = ->
        console.log 'Disabling PROS'
        atom.commands.dispatch atom.views.getView(atom.workspace.getActiveTextEditor()),
          'PROS:Toggle-PROS'
      console.log @button
      @attach()

    attach: -> @statusBarProvider.addRightTile(item: this, priority: -10)
