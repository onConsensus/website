---
layout: page
title: Documentation
permalink: /documentation/
image:
---
Welcome to VJs Mag, your platform for sharing insights, articles, and visual content about the vibrant world of VJing and audiovisual art forms. To ensure your contributions reach our audience effectively, it is essential to understand the process of publishing documentation on our platform. This guide will walk you through the necessary steps and best practices for creating and publishing your work on VJs Mag.

### Table Of Contents

1. [Create an Account on GitHub](#1)
2. [Creating a private repository](#2)
3. [Creating Your Content](#3)
4. [Adding Content](#4)
  - [Paragraphs](#4.1)
  - [Headings](#4.2)
  - [Ordered list](#4.3)
  - [Unordered list](#4.4)
  - [Table](#4.5)
  - [Quotes](#4.6)
  - [Syntax Highlighter](#4.7)
  - [Images](#4.8)
  - [Youtube Embed](#4.9)
  - [Vimeo Embed](#4.10)
  - [Links](#4.11)
5. [Uploading Media](#5)
6. [Link Text](#6)
7. [Link Text](#7)
8. [Link Text](#8)
9. [Link Text](#9)
10. [Link Text](#10)

***

<a name="1"></a>

# How to Create an Account on GitHub

VJ journalists will need to create an account on GitHub. If you already have an account, you can skip this step.

## How to Create an Account on GitHub

1. **Go to GitHub's Sign-Up Page**:
   - Navigate to [GitHub Join Page](https://github.com/join) [[1](https://github.com/join)].

2. **Fill Out the Registration Form**:
   - **Email Address**: Enter your email address.
   - **Password**: Create a strong password.
   - **Username**: Choose a unique username.
   - **Email Preferences**: Select your email preferences.

3. **Verify Your Account**:
   - Complete the CAPTCHA to verify that you are not a robot.

4. **Choose Your Plan**:
   - Select the plan that suits your needs (you can start with the free plan).

5. **Verify Your Email Address**:
   - GitHub will send a verification email to your provided email address. Open the email and click the verification link to activate your account.

## Additional Resources
- For detailed instructions, you can refer to the GitHub documentation on [creating an account](https://docs.github.com/en/get-started/start-your-journey/creating-an-account-on-github) [[2](https://docs.github.com/en/get-started/start-your-journey/creating-an-account-on-github)].

By following these steps, you will have a GitHub account ready to use for publishing and collaborating on VJs Mag.

***

<a name="2"></a>
# Creating a private repository

Creating a private repository on GitHub ensures that only you and your collaborators can access the repository. Here are the steps to create a private repository:

1. **Open GitHub**:
   - Navigate to [GitHub](https://github.com) and sign in to your account.

2. **Go to Your Repositories**:
   - Click on your profile icon in the upper-right corner of the page.
   - From the dropdown menu, select "Your repositories."

3. **Create a New Repository**:
   - Click the "New" button to start creating a new repository.

4. **Fill in Repository Details**:
   - **Repository Name**: Type a memorable name for your repository.
   - **Description**: Optionally, add a description for your repository.
   - **Visibility**: Select the "Private" option to ensure the repository is not visible to the public.
   - **Initialize Repository**: Optionally, you can initialize the repository with a README, .gitignore, or a license file.

5. **Create Repository**:
   - Click the "Create repository" button to finalize the creation of your private repository.

### Additional Steps for Existing Repositories

If you want to change an existing public repository to private:

1. **Navigate to the Repository**:
   - Go to the main page of your repository on GitHub.

2. **Access Settings**:
   - Under your repository name, click on "Settings."

3. **Change Visibility**:
   - In the "Danger Zone" section at the bottom, click "Change repository visibility."
   - Select "Make private" and follow the prompts to confirm.

Following these steps will help you create a private repository on GitHub, ensuring your project remains confidential and secure.

***

<a name="3"></a>
# How to Create Content in Your GitHub Repository

Once you have created your first repository, you can start adding content by following these steps:

## Create a Markdown (.md) File

1. **Navigate to Your Repository**:
   - Go to your repository on GitHub.

2. **Create a New File**:
   - Click on the "Add file" button and select "Create new file".

3. **Name Your File**:
   - Name your file in the format `year-month-day-article-title.md`. For example: `2022-05-07-my-article-title.md`.

## Add a Header to Your Markdown File

At the beginning of your Markdown file, add the following header to define the layout, title, date, author, image, and tags for your article:

```markdown
---
layout: post
title: My article title
date: 2022-05-07 15:01:35 +0300
author: First Lastname
image: '/images/33.jpg'
tags: [category]
---
```

- **layout**: Indicates the layout template to be used.
- **title**: The title of your article.
- **date**: The publication date and time of the article.
- **author**: Your name.
- **image**: The path to an image that represents the article.
- **tags**: A list of categories or tags related to the article.

***

<a name="4"></a>
## Adding Content

Below the header, you can start adding your content. Use Markdown syntax to format your article. Here are some basic elements:

***

<a name="4.1"></a>
### Paragraphs

A paragraph looks like this — Globally incubate standards compliant channels before scalable benefits. Quickly disseminate superior deliverables whereas web-enabled applications. Quickly drive clicks-and-mortar catalysts for change before vertical architectures. Credibly reintermediate backend ideas for cross-platform models. Continually reintermediate integrated processes through technically sound intellectual capital. Holistically foster superior methodologies.

```
A paragraph looks like this — Globally incubate standards compliant channels before scalable benefits. Quickly disseminate superior deliverables whereas web-enabled applications. Quickly drive clicks-and-mortar catalysts for change before vertical architectures. Credibly reintermediate backend ideas for cross-platform models. Continually reintermediate integrated processes through technically sound intellectual capital. Holistically foster superior methodologies.
```

***
<a name="4.2"></a>

### Headings

# H1 Default styles for headings
## H2 Default styles for headings
### H3 Default styles for headings
#### H4 Default styles for headings
##### H5 Default styles for headings
###### H6 Default styles for headings

```
# H1 Default styles for headings
## H2 Default styles for headings
### H3 Default styles for headings
#### H4 Default styles for headings
##### H5 Default styles for headings
###### H6 Default styles for headings
```

***
<a name="4.3"></a>

### Ordered list example:

1. Morbi lectus risus iaculis vel suscipit turpis quis.
2. Curabitur sit amet mauris morbi in dui quis est pulvinar ullamcorper nulla facilisi.
3. Nullam mauris orci aliquet iaculis et neque viverra vitae ligula.
4. Proin quam etiam ultrices suspendisse in justo eu magna luctus lacinia suscipit.
5. Aenean lectus elit fermentum non convallis id sagittis at neque mauris orci.

```
1. Morbi lectus risus iaculis vel suscipit turpis quis.
2. Curabitur sit amet mauris morbi in dui quis est pulvinar ullamcorper nulla facilisi.
3. Nullam mauris orci aliquet iaculis et neque viverra vitae ligula.
4. Proin quam etiam ultrices suspendisse in justo eu magna luctus lacinia suscipit.
5. Aenean lectus elit fermentum non convallis id sagittis at neque mauris orci.
```

***
<a name="4.4"></a>

### Unordered list example:

* Etiam ultrices. Suspendisse in justo massa fusce non.
* Sed non quam. In vel mi sit amet augue congue elementum.
* Suspendisse in justo eu magna luctus suscipit sed lectus.
* Quisque volutpat condimentum velit class aptent taciti sociosqu torquent.
* Aenean lectus elit fermentum non convallis id sagittis at neque.

```
* Etiam ultrices. Suspendisse in justo massa fusce non.
* Sed non quam. In vel mi sit amet augue congue elementum.
* Suspendisse in justo eu magna luctus suscipit sed lectus.
* Quisque volutpat condimentum velit class aptent taciti sociosqu torquent.
* Aenean lectus elit fermentum non convallis id sagittis at neque.
```

***
<a name="4.5"></a>

## Table

<div class="table-container">
  <table>
    <tr><th>Header 1</th><th>Header 2</th><th>Header 3</th><th>Header 4</th><th>Header 5</th></tr>
    <tr><td>Row:1 Cell:1</td><td>Row:1 Cell:2</td><td>Row:1 Cell:3</td><td>Row:1 Cell:4</td><td>Row:1 Cell:5</td></tr>
    <tr><td>Row:2 Cell:1</td><td>Row:2 Cell:2</td><td>Row:2 Cell:3</td><td>Row:2 Cell:4</td><td>Row:2 Cell:5</td></tr>
    <tr><td>Row:3 Cell:1</td><td>Row:3 Cell:2</td><td>Row:3 Cell:3</td><td>Row:3 Cell:4</td><td>Row:3 Cell:5</td></tr>
    <tr><td>Row:4 Cell:1</td><td>Row:4 Cell:2</td><td>Row:4 Cell:3</td><td>Row:4 Cell:4</td><td>Row:4 Cell:5</td></tr>
    <tr><td>Row:5 Cell:1</td><td>Row:5 Cell:2</td><td>Row:5 Cell:3</td><td>Row:5 Cell:4</td><td>Row:5 Cell:5</td></tr>
    <tr><td>Row:6 Cell:1</td><td>Row:6 Cell:2</td><td>Row:6 Cell:3</td><td>Row:6 Cell:4</td><td>Row:6 Cell:5</td></tr>
  </table>
</div>

```
<div class="table-container">
  <table>
    <tr><th>Header 1</th><th>Header 2</th><th>Header 3</th><th>Header 4</th><th>Header 5</th></tr>
    <tr><td>Row:1 Cell:1</td><td>Row:1 Cell:2</td><td>Row:1 Cell:3</td><td>Row:1 Cell:4</td><td>Row:1 Cell:5</td></tr>
    <tr><td>Row:2 Cell:1</td><td>Row:2 Cell:2</td><td>Row:2 Cell:3</td><td>Row:2 Cell:4</td><td>Row:2 Cell:5</td></tr>
    <tr><td>Row:3 Cell:1</td><td>Row:3 Cell:2</td><td>Row:3 Cell:3</td><td>Row:3 Cell:4</td><td>Row:3 Cell:5</td></tr>
    <tr><td>Row:4 Cell:1</td><td>Row:4 Cell:2</td><td>Row:4 Cell:3</td><td>Row:4 Cell:4</td><td>Row:4 Cell:5</td></tr>
    <tr><td>Row:5 Cell:1</td><td>Row:5 Cell:2</td><td>Row:5 Cell:3</td><td>Row:5 Cell:4</td><td>Row:5 Cell:5</td></tr>
    <tr><td>Row:6 Cell:1</td><td>Row:6 Cell:2</td><td>Row:6 Cell:3</td><td>Row:6 Cell:4</td><td>Row:6 Cell:5</td></tr>
  </table>
</div>
```

***
<a name="4.6"></a>

## Quotes

#### A quote looks like this:

> The longer I live, the more I realize that I am never wrong about anything, and that all the pains I have so humbly taken to verify my notions have only wasted my time!
>
> <cite>– George Bernard Shaw</cite>

```
> The longer I live, the more I realize that I am never wrong about anything, and that all the pains I have so humbly taken to verify my notions have only wasted my time!
>
> <cite>– George Bernard Shaw</cite>
```

***
<a name="4.7"></a>

## Syntax Highlighter

```css
body {
  margin: 0;
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  width: 100vw;
  background-color: #1c2021;
}

li {
  width: 200px;
  min-height: 250px;
  border: 1px solid #000;
  display: inline-block;
  vertical-align: top;
  margin: 5px;
}
```

```js
  $('.top').click(function () {
    $('html, body').stop().animate({ scrollTop: 0 }, 'slow', 'swing');
  });
  $(window).scroll(function () {
    if ($(this).scrollTop() > $(window).height()) {
      $('.top').addClass("top-active");
    } else {
      $('.top').removeClass("top-active");
    };
  });
```

***
<a name="4.8"></a>

## Images

![Shopping]({{site.baseurl}}/images/20.jpg#wide)
*Photo by [Tim Douglas](https://www.pexels.com/photo/happy-woman-jumping-with-shopping-bags-6567607/) on [Pexels](https://www.pexels.com)*

<div class="gallery-box">
  <div class="gallery">
    <img src="/images/12.jpg" loading="lazy">
    <img src="/images/24.jpg" loading="lazy">
    <img src="/images/09.jpg" loading="lazy">
    <img src="/images/14.jpg" loading="lazy">
    <img src="/images/19-1.jpg" loading="lazy">
    <img src="/images/06-2.jpg" loading="lazy">
  </div>
  <em>Gallery / <a href="https://www.pexels.com" target="_blank">Pexels</a></em>
</div>

![Salad]({{site.baseurl}}/images/23.jpg)
*Photo by [Valeria Boltneva](https://www.pexels.com/photo/salmon-dish-with-vegetables-1516415/) on [Pexels](https://www.pexels.com)*

```
![Shopping]({{site.baseurl}}/images/20.jpg#wide)
*Photo by [Tim Douglas](https://www.pexels.com/photo/happy-woman-jumping-with-shopping-bags-6567607/) on [Pexels](https://www.pexels.com)*

<div class="gallery-box">
  <div class="gallery">
    <img src="/images/12.jpg" loading="lazy">
    <img src="/images/24.jpg" loading="lazy">
    <img src="/images/09.jpg" loading="lazy">
    <img src="/images/14.jpg" loading="lazy">
    <img src="/images/19-1.jpg" loading="lazy">
    <img src="/images/06-2.jpg" loading="lazy">
  </div>
  <em>Gallery / <a href="https://www.pexels.com" target="_blank">Pexels</a></em>
</div>

![Salad]({{site.baseurl}}/images/23.jpg)
*Photo by [Valeria Boltneva](https://www.pexels.com/photo/salmon-dish-with-vegetables-1516415/) on [Pexels](https://www.pexels.com)*
```

***
<a name="4.9"></a>

## Youtube Embed

<p><iframe src="https://www.youtube.com/embed/LiL2FY9n2DAnuJ5U" loading="lazy" frameborder="0" allowfullscreen></iframe></p>

```
<p><iframe src="https://www.youtube.com/embed/LiL2FY9n2DAnuJ5U" loading="lazy" frameborder="0" allowfullscreen></iframe></p>
```

***
<a name="4.10"></a>

## Vimeo Embed

<p><iframe src="https://player.vimeo.com/video/55630271?h=d36b8b4cbb" loading="lazy" width="640" height="360" frameborder="0" allowfullscreen></iframe></p>

```
<p><iframe src="https://player.vimeo.com/video/55630271?h=d36b8b4cbb" loading="lazy" width="640" height="360" frameborder="0" allowfullscreen></iframe></p>
```

***
<a name="4.11"></a>

### Links
```markdown
[Link text](http://example.com)
```

***