--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

--
-- Data for Name: grammar_elements; Type: TABLE DATA; Schema: public; Owner: -
--

COPY grammar_elements (id, name, label, input_template, grammar_version, is_deleted, description, created_at, updated_at) FROM stdin;
0f3b0cfa-0ef9-4019-b379-7d68c148aec8	Large Header	header-large	{"data": "STRING"}	1	f	Largest Header	2016-02-25 00:43:16.677246+05:30	2016-02-25 00:43:16.677246+05:30
9e501d1a-651c-4d58-8b15-19e9cc5506a1	Medium Header	header-medium	{"data": "STRING"}	1	f	Medium Header	2016-02-25 00:43:16.677246+05:30	2016-02-25 00:43:16.677246+05:30
d237a5bd-d2b9-4134-b80c-63b055ed3385	Small Header	header-small	{"data": "STRING"}	1	f	Small Header	2016-02-25 00:43:16.677246+05:30	2016-02-25 00:43:16.677246+05:30
c2e952d7-cc97-458b-9545-9f4e2cc722cb	Text	text	{"data": "STRING"}	1	f	Normal text	2016-02-25 00:43:16.677246+05:30	2016-02-25 00:43:16.677246+05:30
a984c65d-8548-4b4c-98f4-32be0d57fde9	Image	image	{"data": {"image_large": "STRING", "image_small": "STRING"}}	1	f	Basic Image Element	2016-02-25 00:43:16.677246+05:30	2016-02-25 00:43:16.677246+05:30
4b732dba-cdcd-49ed-8abf-85bf0c30f265	Double Image	double-image	{"data": {"left": {"image_large": "STRING", "image_small": "STRING"}, "right": {"image_large": "STRING", "image_small": "STRING"}}}	1	f	Two Basic Image Elements Side by Side	2016-02-25 00:43:16.677246+05:30	2016-02-25 00:43:16.677246+05:30
cb454d8a-5847-49fa-955d-0d838e9d3829	Input Edit TextBox	input-edit-text	{"data": {"hint": "STRING", "placeholder": "STRING"}}	1	f	Editable text area input element	2016-02-25 00:43:16.677246+05:30	2016-02-25 00:43:16.677246+05:30
b89c6ee1-e621-4318-a972-24a782eef28a	Input ColorPalette	input-color-palette	{"data": ["STRING"]}	1	f	Color palette input element. Takes hex array as input along with "MULTI" & "TRANS" for multicolor & transparent resp.	2016-02-25 00:43:16.677246+05:30	2016-02-25 00:43:16.677246+05:30
93c07b3f-a25b-42ae-a64d-d246682d5b11	WhiteSpace	white-space	{}	1	f	Kind of new line character	2016-03-19 00:09:39.187487+05:30	2016-03-19 00:09:39.187487+05:30
1c8f02af-0d3b-4007-ad47-1bce032eedd3	Collapsible Text	collapsible-text	{"data": "STRING"}	1	f	Collapsible Text shows some fixed number of lines in default view. On click it expands shows the remaining text	2016-04-11 14:25:40.791052+05:30	2016-04-11 14:25:40.791052+05:30
fb8d2450-04d8-445a-981f-3b90c443fca9	Color Swatch	color-swatch	{"data": {"hex": "STRING", "text": "STRING"}}	1	f	Color Swatch component	2016-05-03 00:07:46.759095+05:30	2016-05-03 00:07:46.759095+05:30
7a83648d-4c43-4315-80fe-70bf4b3166ad	Input Radiobutton	input-radiobutton	{"data": ["STRING"], "buckets": [{"name": "STRING", "size": "STRING"}], "is_nested": "true|false"}	1	f	RadioButton input element	2016-02-25 00:43:16.677246+05:30	2016-05-18 16:52:17.904059+05:30
3ae1c82e-e02a-4e4b-9d2a-076897cdd9d4	Input Checkbox	input-checkbox	{"data": ["STRING"], "buckets": [{"name": "STRING", "size": "STRING"}], "is_nested": "true|false"}	1	f	Checkbox (multiselect) input element	2016-02-25 00:43:16.677246+05:30	2016-05-18 16:52:17.904059+05:30
69dcad4f-8e92-4923-b71a-54dba320be50	Input Tiles	input-tiles	{"data": ["STRING"], "responseType": "SINGLESELECT|MULTISELECT"}	1	f	Tiles input element	2016-06-20 18:20:23.012657+05:30	2016-06-20 18:20:23.012657+05:30
a53f51cf-9863-4069-b4de-ad1bd16ea82c	Grid	grid	{"data": [{"text": "?STRING", "image": "STRING"}]}	1	f	Grid element to show data in tabular form	2016-02-25 00:43:16.677246+05:30	2016-02-25 00:43:16.677246+05:30
5b06577c-bb88-4e0c-9898-5c8f3daef9ef	Input Grid	input-grid	{"data": [{"text": "?STRING", "image": "STRING"}], "responseType": "SINGLESELECT|MULTISELECT"}	1	f	Grid element to show input options (text & image) in tabular form	2016-02-25 00:43:16.677246+05:30	2016-02-25 00:43:16.677246+05:30
230a1c8e-d9af-4b4b-8c05-de92f0c2555c	Toggle List	toggle-list	{"data": [{"text": "STRING", "image": "?STRING"}]}	1	f	Toggle list	2016-04-09 13:26:21.399264+05:30	2016-04-09 13:26:21.399264+05:30
\.


--
-- Data for Name: integration_providers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY integration_providers (id, name, label, website, created_at, updated_at, logo_url) FROM stdin;
a11bd32e-66ed-4de5-abce-d708cd5f7cd5	Facebook	fb	www.facebook.com	2015-09-22 02:08:43.723123+05:30	2015-09-22 02:08:43.723123+05:30	\N
860fb6a5-01f4-4f32-aaad-496ade2f61af	Google	goog	www.google.com	2015-09-22 02:08:43.723123+05:30	2015-09-22 02:08:43.723123+05:30	\N
bde3ebfe-85d3-49fb-8412-9fcef61a6f87	PayU	payu	payu.com	2015-09-22 02:08:43.847+05:30	2015-09-22 02:08:43.847+05:30	https://easydigitaldownloads.com/wp-content/uploads/2013/12/payu-india-payment-gateway.png
2f526f02-2252-4c37-ba3b-38dd2b9f6464	Freecharge	freecharge	www.freecharge.in	2015-09-27 20:13:02.939516+05:30	2015-09-27 20:13:02.939516+05:30	http://i62.tinypic.com/10wtfgk.png
ac73a32b-482c-45b5-b7d5-4ad43d5a2038	Myntra	myntra	www.myntra.com	2015-09-27 20:14:57.221117+05:30	2015-09-27 20:14:57.221117+05:30	https://s3-ap-southeast-1.amazonaws.com/playmentproduction/public/coupon_images/myntra-min.png
30ecfa86-6981-4dcb-8b72-c92f514aecec	BookMyShow	bookmyshow	www.bookmyshow.com	2015-09-27 20:14:20.820984+05:30	2015-09-27 20:14:20.820984+05:30	https://s3-ap-southeast-1.amazonaws.com/playmentproduction/public/coupon_images/bms-min.png
ecbb6616-43f0-44f4-a26b-50c90ef9a594	Flipkart	flipkart	www.flipkart.com	2015-09-27 19:32:27.870499+05:30	2015-09-27 19:32:27.870499+05:30	http://d197osy5kcs7h2.cloudfront.net/coupon_images/flipkart-2-min.png
c0a72a50-e04e-4730-9747-03607a0e4d84	Amazon.in	amazon.in	www.amazon.in	2015-09-27 20:11:46.321104+05:30	2015-09-27 20:11:46.321104+05:30	http://d197osy5kcs7h2.cloudfront.net/coupon_images/amazon-2-min.png
10798ac4-c5b6-4e54-970b-165f89e3b7f6	PayTM	paytm	paytm.com	2015-09-22 02:08:43.854+05:30	2015-09-22 02:08:43.854+05:30	http://d197osy5kcs7h2.cloudfront.net/coupon_images/paytm-2-min.png
\.


--
-- Data for Name: micro_task_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY micro_task_type (id, name) FROM stdin;
1	PUBLIC
2	FALLBACK
3	QUALIFIER
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY roles (id, name, label, approval_strategy, created_at, updated_at) FROM stdin;
93dd9058-0608-4e7d-b427-a1481b73d35d	admin	admin	1	2015-09-22 02:12:01.432+05:30	2015-09-22 02:15:06.361+05:30
aa9ceba9-fa12-4d4d-aac0-f50caeca86a4	worker	worker	1	2015-09-22 02:12:01.463+05:30	2015-09-22 02:15:06.391+05:30
a6bd404f-6e54-41c1-99ec-5b51e115750c	player	player	1	2015-09-22 03:00:57.256+05:30	2016-10-10 19:56:52.342+05:30
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: public; Owner: -
--

COPY tags (id, name, value, is_deleted) FROM stdin;
fe818020-e1bc-4d21-ada9-f249e5d89c41	USERID	*	f
ed13ff6e-d2bf-43f5-a66c-75292557fef4	GENDER	MALE	f
339b7fce-a99f-41a3-a595-06d022cb5d95	GENDER	FEMALE	f
276ed45c-6a15-46c9-9b5e-442e4d462b4a	AGE	BELOW21	f
ade5d464-d7cd-4299-ad71-d77ab869bfc2	AGE	ABOVE21	f
\.


--
-- PostgreSQL database dump complete
--

