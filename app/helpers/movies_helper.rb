module MoviesHelper
  def movie(opts)
    iframe = content_tag(
      :iframe,
      '', # empty body
      width: 640,
      height: 480,
      src: "https://www.youtube.com/embed/#{opts[:movie_id]}",
      frameborder: 0,
      allowfullscreen: true
    )
    content_tag(:div, iframe, class: 'youtube-container')
  end
end